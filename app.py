#!flask/bin/python
from flask import Flask
from flask import jsonify
from flask import request
import os
import subprocess
import logging

app = Flask(__name__)

# get logger instance
LOGGER = logging.getLogger('git-auto-deploy')
LOGGER_CONFIGURED = False


def configure_logger(global_logger, log_level):
    # type: (logging.Logger, str) -> None
    """Configures the main logger object.
    log level is set for logging level.

    :param global_logger: main logger instance
    :param log_level:
        logging level [ error > warning > info > debug > off ]
    :return:
    """
    global LOGGER_CONFIGURED
    if not LOGGER_CONFIGURED:
        log_levels = {
            'off': logging.NOTSET,
            'debug': logging.DEBUG,
            'info': logging.INFO,
            'warning': logging.WARNING,
            'error': logging.ERROR,
            'critical': logging.CRITICAL
        }
        if log_level not in log_levels.keys():
            raise ValueError("Logging level not valid: '{}'".format(log_level))
        else:
            log_level = log_levels[log_level]
        global_logger.setLevel(logging.DEBUG)

        # create file handler which logs even debug messages
        if os.path.exists("logs/"):
            file_handler = logging.FileHandler('logs/python__git-auto-deployer.log')
        else:
            file_handler = logging.FileHandler('python__git-auto-deployer.log')
        file_handler.setLevel(log_level)
        # create console handler with a higher log level
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        # create formatter and add it to the handlers
        formatter = logging.Formatter('%(asctime)s :%(name)-16s: [%(levelname)s] -> %(message)s')
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        # add the handlers to the logger
        global_logger.addHandler(file_handler)
        global_logger.addHandler(console_handler)
        LOGGER_CONFIGURED = True


@app.route('/webhooks/git', methods=['GET', 'POST'])
def deploy():
    """Function called from API endpoint to update git repo.
    It runs 'git pull' command on the repo path given.

    :return:
    """

    # configure logging properties with configuration given
    configure_logger(LOGGER, 'info')

    # API response model
    http_response = {
        'success': True,
        'git_cmd_msg': 'None',
        'git_commit_id': 'None',
        'git_commit_msg': 'None',
        'error': 'None',
        'exit_code': 200,
        'repo_path': "None"
    }

    error_msg = None
    exit_code = 200
    git_cmd_msg = ""
    git_commit_id = ""
    git_commit_msg = ""

    # get git repo path from request arguments
    repo_path = request.args.get('repo_path')
    LOGGER.info("repo_path argument: '{}'".format(repo_path))

    if repo_path is None:
        # not repo path given on request.
        error_msg = "'repo_path' argument is missing in the HTTP Request. " \
                    "Try to add: ?repo_path={path/to/repo} to your request"
        LOGGER.error("ERROR: {}".format(error_msg))

    else:
        # repo_path given in request. Validate it.
        if not os.path.exists(repo_path):
            error_msg = "repo_path does not exists: '{}'".format(repo_path)
            LOGGER.error("ERROR: {}".format(error_msg))

        if error_msg is None:
            LOGGER.info("Git Repo path is valid: '{}'".format(repo_path))
            path = os.path.normpath(repo_path)

            # try to pull the latest changes from repo (if any)
            try:
                LOGGER.info("Updating git repo (git pull): '{}'".format(repo_path))
                # pull the latest code (automatic deployment)
                git_cmd_msg = execute_cmd(
                    ['git', 'pull', 'origin', 'master'], cwd=repo_path)

                # get git repo metadata with commands on the repo
                git_commit_id = execute_cmd(
                    ['git', 'rev-parse', 'HEAD'], cwd=repo_path)
                git_commit_msg = execute_cmd(
                    ['git', 'log', '--format=%B', '-n', '1', 'HEAD'], cwd=repo_path)

            except Exception as ex:
                error_msg = "{}".format(ex)
                LOGGER.error("ERROR: {}".format(error_msg))

    if error_msg is not None:
        set_fail_response(http_response, exit_code, error_msg)
    else:
        # build OK response with all data available
        http_response['git_cmd_msg'] = git_cmd_msg
        http_response['git_commit_id'] = git_commit_id
        http_response['git_commit_msg'] = git_commit_msg

        http_response['repo_path'] = repo_path
        http_response['exit_code'] = exit_code

        LOGGER.info("Request is Successful. "
                    "Sending response back to client. '{}'".format(http_response))

    return jsonify(http_response), exit_code


@app.route('/', methods=['GET'])
def main():
    return jsonify({'msg': 'Invalid Path. Contact Administrator.'}), 404


def set_fail_response(http_response, code, error_msg):
    # type: (dict, int, str) -> None
    """

    :param http_response:
    :param code:
    :param error_msg:
    :return:
    """
    # set all medata to a Bad Request
    code = 400
    http_response['success'] = False
    http_response['error'] = error_msg
    http_response['exit_code'] = code


def execute_cmd(command, **kwargs):
    # type: (list, **str) -> str
    """Executes a command on the OS command line
    from the host in which this script runs

    :param command:
    :param kwargs:
    :return:
    """
    args = []
    args += command
    cwd = kwargs.pop('cwd', '.')
    try:
        output = subprocess.check_output(
            args,
            stderr=subprocess.STDOUT,
            cwd=cwd
        )
        if isinstance(output, (bytes, bytearray)):
            output = output.decode('UTF-8')
    except subprocess.CalledProcessError as exception:
        raise Exception('Failed for command:{}'.format(' '.join(args)))
    except Exception as exception:
        raise Exception('General error: {}'.format(exception))
    return output


if __name__ == '__main__':
    app.run(debug=True)
