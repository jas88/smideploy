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

static int debug = 0;

std::vector <pid_t> kids;
std::map <pid_t, char * const> jobs;

static void shutdown();

static pid_t spawn(char * const cmd, const char **env);

static void shutdown() {
    auto it = jobs.begin();
    while (it != jobs.end()) {
        if (kill(it->first, SIGTERM)) {
            fprintf(stderr, "Error %d sending SIGTERM to PID %d (%s)\n",
                    errno, it->first, it->second);
        free(it->second);
        }
        it++;
    }
    jobs.clear();

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

static pid_t spawn(char * cmd, const char **env) {
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
            cmd = strdup(cmd);
            jobs.insert(std::pair <pid_t, char * const>(kid, cmd));
            return kid;
    }
}

static int init(const char *conffile, const char **env) {
    YAML::Node config;

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
        char *s = strdup(jobstring.c_str());
        if (strcmp(s, "wait") == 0) {
            fprintf(stderr, "Waiting 30 seconds for daemons to initialise\n");
            sleep(30);
        } else {
            spawn(s, env);
            fprintf(stderr, "Job: %s\n", s);
        }
        free(s);
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

static int loop(const char *conffile, const char **env) {
    int signum;
    sigset_t mask = {0};

    sigemptyset(&mask);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGTERM);
    sigaddset(&mask, SIGCHLD);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1) {
        perror("sigprocmask");
        return 1;
    }

    if (init(conffile, env) > 0)
        return 1;

    while (true) {
        if (sigwait(&mask, &signum)) {
            perror("sigwait");
            return 1;
        }
        if (signum != SIGCHLD) {
            shutdown();
            return 0;
        } else {
            pid_t n;
            int status;
            while ((n = waitpid(-1, &status, WNOHANG)) > 0) {
                fprintf(stderr, "%d exited with status %d, respawning\n",
                        n, status);
                try {
                    spawn(jobs.at(n), env);
                    free(jobs.at(n));
                    jobs.erase(n);
                } catch (std::out_of_range&) {
                    // Unwanted orphan, ignore
                }
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
    return loop(conffile, env);
}
