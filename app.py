import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), 'dependencies'))
from awsgi import response

from flask import Flask, request, jsonify, send_file
import boto3
import uuid

app = Flask(__name__)

s3 = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'bucketpront')

sys.path.append(os.path.join(os.path.dirname(__file__), 'dependencies'))

@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    file_key = f"uploads/{uuid.uuid4()}-{file.filename}"

    try:
        s3.upload_fileobj(file, BUCKET_NAME, file_key)
        return jsonify({'message': 'File uploaded successfully!', 'file_key': file_key})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/files', methods=['GET'])
def list_files():
    try:
        response = s3.list_objects_v2(Bucket=BUCKET_NAME)
        files = [obj['Key'] for obj in response.get('Contents', [])]
        return jsonify({'files': files})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    try:
        file_obj = s3.get_object(Bucket=BUCKET_NAME, Key=filename)
        return send_file(
            file_obj['Body'],
            download_name=filename,
            as_attachment=True
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def lambda_handler(event, context):
    return response(app, event, context)


if __name__ == "__main__":
    app.run(debug=True)