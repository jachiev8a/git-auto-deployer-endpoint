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


def configure_logger(global_logger, log_level):
    # type: (logging.Logger, str) -> None
    """Configures the main logger object.
    log level is set for logging level.

    :param global_logger: main logger instance
    :param log_level:
        logging level [ error > warning > info > debug > off ]
    :return:
    """
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
    file_handler = logging.FileHandler('git-auto-deployer.log')
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


@app.route('/webhooks/git', methods=['GET'])
def deploy():

    http_response = {
        'success': True,
        'git_cmd_msg': 'None',
        'error': 'None',
        'exit_code': 200,
        'repo_path': "None"
    }

    error_msg = None
    exit_code = 200
    git_cmd_msg = ""

    # get git repo path from request arguments
    repo_path = request.args.get('repo_path')
    LOGGER.info("repo_path argument: '{}'".format(repo_path))

    if repo_path is None:
        error_msg = "'repo_path' argument is missing in the HTTP Request. Try to add: ?repo_path={path/to/repo}"
        LOGGER.error("ERROR: {}".format(error_msg))

    elif not os.path.exists(repo_path):
        error_msg = "repo_path does not exists: '{}'".format(repo_path)
        LOGGER.error("ERROR: {}".format(error_msg))

        if error_msg is None:
            path = os.path.normpath(repo_path)
            # try to pull the repo
            try:
                LOGGER.info("Updating git repo: '{}'".format(repo_path))
                git_cmd_msg = execute_cmd(['git', 'pull', 'origin', 'master'], cwd=repo_path)
            except Exception as ex:
                error_msg = "{}".format(ex)
                LOGGER.error("ERROR: {}".format(error_msg))

    if error_msg is not None:
        failure_response(http_response, exit_code, error_msg)
    else:
        http_response['git_cmd_msg'] = git_cmd_msg
        http_response['repo_path'] = repo_path
        http_response['exit_code'] = exit_code
        LOGGER.info("Request is Successful. Sending response back to client. '{}'".format(http_response))

    return jsonify(http_response), exit_code


@app.route('/', methods=['GET'])
def main():
    return jsonify({'msg': 'Invalid Path. Contact Administrator.'}), 404


def failure_response(http_response, code, msg):
    code = 400
    http_response['success'] = False
    http_response['error'] = msg
    http_response['exit_code'] = code


def execute_cmd(command, **kwargs):
    # type: (list, **str) -> str
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
    # configure logging properties with configuration given
    configure_logger(LOGGER, 'info')
    app.run(debug=True)
