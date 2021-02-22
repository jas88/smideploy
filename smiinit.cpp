/*
 * Copyright 2021 James A Sutherland / University of Dundee
 * */

#include <yaml-cpp/yaml.h>
#include <assert.h>
#include <sys/types.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <string.h>
#include <map>
#include <vector>

static int debug = 0, shuttingdown = 0;

std::vector <pid_t> kids;
std::map <pid_t, const char *> jobs;

static void shutdown();

static pid_t spawn(const char *cmd, const char **env);

static int rpipe, wpipe;

static_assert(sizeof(pid_t) == sizeof(int), "Size mismatch!");

static void sig_h(int sig) {
    switch (sig) {
        case SIGCHLD: {
            pid_t p;
            if (!shuttingdown) {
                while ((p = waitpid(-1, NULL, WNOHANG)) > 0) {
                    write(wpipe, &p, sizeof(p));
                }
            }
            return;
        }

        case SIGTERM: {
            int n = -1;
            shuttingdown = 1;
            if (write(wpipe, &n, sizeof(n)) != sizeof(n)) {
                perror("write");
                exit(EXIT_FAILURE);
            }
            return;
        }

        default:
            fprintf(stderr, "WARNING:Unexpected signal %d\n", sig);
            return;
    }
}

static void shutdown() {
    for (pid_t kid : kids) {
        jobs.erase(kid);
        if (kill(kid, SIGTERM)) {
            fprintf(stderr, "Error %d sending SIGTERM to PID %d\n", errno, kid);
        }
    }

    sleep(3);

    for (pid_t kid : kids) {
        if ((waitpid(kid, NULL, WNOHANG) == 0)
            && kill(kid, SIGKILL)
            && errno != ESRCH) {
            fprintf(stderr, "Error %d sending SIGTERM to PID %d\n", errno, kid);
        }
    }
    kids.clear();
}

static pid_t spawn(const char *cmd, const char **env) {
    static const char *shell = "/bin/sh", *dashc = "-c";
    pid_t kid;
    switch (kid = fork()) {
        case -1:
            perror("fork");
            return -1;

        case 0:
        {
            const char *args[] = { shell, dashc, cmd, 0 };
            execve(shell, (char*const*)args, (char*const*)env);
            perror(cmd);
            return -1;  // Only really returns on failure
        }

        default:
            jobs.insert(std::pair <pid_t, const char *>(kid, cmd));
            return kid;
    }
}

static int init(const char *conffile, const char **env) {
    struct sigaction sa = {};
    int pipefd[2];
    YAML::Node config;

    if (pipe(pipefd)
        || fcntl(pipefd[0], F_SETFL, O_NONBLOCK)
        || fcntl(pipefd[1], F_SETFL, O_NONBLOCK)) {
        perror("pipe");
        return 1;
    }
    rpipe = pipefd[0];
    wpipe = pipefd[1];

    sa.sa_handler = sig_h;
    sa.sa_flags = SA_RESTART;
    if (sigaction(SIGTERM, &sa, 0)) {
        perror("sigaction(sigterm)");
        return 1;
    }
    sa.sa_flags|=SA_NOCLDSTOP;
    if (sigaction(SIGCHLD, &sa, 0)) {
        perror("sigaction(sigchld)");
        return 1;
    }

    try {
        config = YAML::LoadFile(conffile);
    } catch (std::exception&) {
        fprintf(stderr, "Missing or invalid config.yaml\n");
        return 1;
    }
    if (!config["jobs"] || !config["jobs"].IsSequence()) {
        fprintf(stderr, "No jobs configured in %s\n", conffile);
        return 1;
    }
    for (auto job : config["jobs"]) {
        auto jobstring = job.as<std::string>();
        const char *s = jobstring.c_str();
        if (strcmp(s, "wait") == 0) {
            fprintf(stderr, "Waiting 30 seconds for daemons to initialise\n");
            sleep(30);
        } else {
            spawn(s, env);
            fprintf(stderr, "Job: %s\n", s);
        }
    }

    return 0;
}

static int help(char *name) {
    fprintf(stderr, "Usage:\t%s [switches]\n"
                   "\t-d       \tDebug\n"
                   "\t-f <file>\tUse the specified YAML configuration file\n"
                   "\t-h       \tPrint help text and exit\n"
                   "\t-v       \tPrint version number and exit\n", name);
    return 0;
}

static int version() {
    return 0;
}

static int loop(const char **env) {
    int pr, n;
    struct pollfd polling = {};
    polling.fd = rpipe;
    polling.events = POLL_IN;
    while (true) {
        pr = poll(&polling, 1, -1);
        if (pr < 0 && errno == EINTR)
            continue;
        if (pr != 1 || read(rpipe, &n, sizeof(n)) != sizeof(n)) {
            perror("read");
            return 1;
        }
        if (n == -1) {
            shutdown();
            return 0;
        } else {
            try {
                spawn(jobs.at(n), env);
            } catch (std::out_of_range&) {
                // Unwanted orphan, ignore
            }
        }
    }
}

int main(int argc, char * const *argv, const char **env) {
    const char *conffile = "config.yaml";
    YAML::Node config;
    int option;

    while ((option=getopt(argc, argv, "df:hv")) != -1) {
        switch (option) {
            case 'd':
                debug++;
                break;
            case 'f':
                conffile = optarg;
                break;
            case 'h':
                return help(*argv);
            case 'v':
                return version();
            default:
                fprintf(stderr, "Warning: Unknown option '%c'\n", option);
                break;
        }
    }
    if (init(conffile, env) > 0)
        return 1;
    return loop(env);
}
