import io
import os
import json
import uuid
import oci

from fdk import response
from io import StringIO


def load_object_content(client, storage_namespace, bucket_name, object_name):
    res = client.get_object(storage_namespace, bucket_name, object_name)
    # Response uses oci._vendor.urllib3.response.HTTPResponse
    httpresponse = res.data.raw
    data_bytes = b''
    for chunk in httpresponse.stream(4096):
        data_bytes += chunk
    return data_bytes.decode('UTF-8')

def prepare_function_response(ctx, res_dict, headers_dict):
    res_str = json.dumps(res_dict)
    rsp = response.Response(ctx, response_data=res_str, headers=headers_dict)
    return rsp


def handler(ctx, data: io.BytesIO=None):
    res_dict = {}
    headers_dict={"Content-Type": "application/json"}

    try:
        # Process input
        bucket_name = "thesis-reports"
        object_name = "secret.txt"
        # Process only .raw.csv
        signer = oci.auth.signers.get_resource_principals_signer()
        client = oci.object_storage.ObjectStorageClient(config={}, signer=signer)
        storage_namespace = client.get_namespace().data
        processed_object_name = object_name.replace('.txt','.processed.txt')
        new_content = load_object_content(client, storage_namespace, bucket_name, object_name)
        client.put_object(storage_namespace, bucket_name, processed_object_name, "I have access to the bucket, the file said:"+new_content)

        res_dict["object_name"] = object_name
        res_dict["result"] = "success"
        return prepare_function_response(ctx, res_dict, headers_dict)

    except (Exception, ValueError) as ex:
        res_dict["result"] = "error"
        res_dict["reason"] = str(ex)

    return prepare_function_response(ctx, res_dict, headers_dict)
