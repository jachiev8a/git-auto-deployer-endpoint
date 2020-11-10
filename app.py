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

LOGGING_FORMAT_CONSOLE = '%(asctime)s | %(module)-24s |: [%(levelname)s] -> %(message)s'
# LOGGING_FORMAT_FILE_1 = '%(asctime)s | %(filename)s-%(funcName)s() [ln:%(lineno)s] | : [%(levelname)s] -> %(message)s'
LOGGING_FORMAT_FILE = '%(asctime)s | [%(levelname)s]: %(module)s.%(funcName)s() [ln:%(lineno)s] | > %(message)s'

# this module file path references
THIS_MODULE_ROOT_DIR = os.path.dirname(__file__)
LOGS_OUTPUT_DIR = os.path.normpath(os.path.join(THIS_MODULE_ROOT_DIR, 'logs'))

# main logging levels used
LOGGING_LEVELS = {
    'off': logging.NOTSET,
    'debug': logging.DEBUG,
    'info': logging.INFO,
    'warning': logging.WARNING,
    'error': logging.ERROR,
    'critical': logging.CRITICAL
}

def configure_logger(
        logger_object,
        log_level_console='warning',
        log_level_file='debug',
        log_file_name=None):
    # type: (logging.Logger, str, str, str) -> None
    """Setup the logger object previously instanced at the scripts.
    Configures the logger level for console output and file handler.

    usage:
        my_logger = logging.getLogger(os.path.basename(__file__))
        setup_logger(my_logger)

    :param logger_object: logger object previously instanced.

    :param log_level_console: logging level for the console output
        options: [ error > warning > info > debug > off ]

    :param log_level_file: logging level for the file output
        options: [ error > warning > info > debug > off ]

    :param log_file_name: name to be given to the generated log file.
    """
    global LOGGER_CONFIGURED
    if not LOGGER_CONFIGURED:
        # main attributes for the class
        # -------------------------------------------------
        logger_object.setLevel(logging.DEBUG)
        logger_level_console = None
        logger_level_file = None

        # default name given (logger_name.log)
        logger_file_name = logger_object.name + '.log'  # default value

        # log file custom configuration (if given)
        if log_file_name is not None:
            logger_file_name = log_file_name + '.log'

        logger_file_path = os.path.normpath(os.path.join(LOGS_OUTPUT_DIR, logger_file_name))

        # validate both logging levels (Console & File)
        # -------------------------------------------------

        # Console
        # ------------
        if log_level_console not in LOGGING_LEVELS.keys():
            raise ValueError("Console Logging level not valid: '{}'".format(log_level_console))
        else:
            logger_level_console = LOGGING_LEVELS[log_level_console]

        # File
        # ------------
        if log_level_file not in LOGGING_LEVELS.keys():
            raise ValueError("Console Logging level not valid: '{}'".format(log_level_file))
        else:
            logger_level_file = LOGGING_LEVELS[log_level_file]

        # generate logs directory (if it does not exist)
        if not os.path.exists(LOGS_OUTPUT_DIR):
            os.mkdir(LOGS_OUTPUT_DIR)

        # create formatter
        # -------------------------------------------------
        log_format_console = logging.Formatter(LOGGING_FORMAT_CONSOLE)
        log_format_file = logging.Formatter(LOGGING_FORMAT_FILE)

        # create handler for console output
        # -------------------------------------------------
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(log_format_console)
        console_handler.setLevel(logger_level_console)
        logger_object.addHandler(console_handler)

        # create handler for file output
        # -------------------------------------------------
        file_handler = logging.FileHandler(logger_file_path)
        file_handler.setFormatter(log_format_file)
        file_handler.setLevel(logger_level_file)
        logger_object.addHandler(file_handler)

        logger_object.debug("['{}'] Logger Started [OK]".format(logger_object.name))
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
