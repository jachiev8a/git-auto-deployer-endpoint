#!flask/bin/python
from flask import Flask
from flask import jsonify
from flask import request
import os
import subprocess

app = Flask(__name__)

REPO_PATH = "d:/_git/jira-groovy-scripts"

@app.route('/webhooks/git', methods=['GET'])
def deploy():

    http_response = {
        'success': True,
        'git_cmd_msg': 'None',
        'error': 'None',
        'exit_code': 200
    }

    error_msg = None
    exit_code = 200
    git_cmd_msg = ""

    REPO_PATH = request.args.get('repo_path')

    if not os.path.exists(REPO_PATH):
        error_msg = "REPO_PATH does not exists: '{}'".format(REPO_PATH)

    if error_msg is None:
        path = os.path.normpath(REPO_PATH)
        # try to pull the repo
        try:
            git_cmd_msg = execute_cmd(['git', 'pull', 'origin', 'master'], cwd=REPO_PATH)
        except Exception as ex:
            error_msg = "{}".format(ex)

    if error_msg is not None:
        failure_response(http_response, exit_code, error_msg)
    else:
        http_response['git_cmd_msg'] = git_cmd_msg
        http_response['exit_code'] = exit_code

    return jsonify(http_response), exit_code


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
    app.run(debug=True)
