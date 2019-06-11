import base64
from protobuf.payload_pb2 import *

encoded_payload = '(insert encoded payload here)'

payload_wrapper = Payload()
# decode the payload from the binary format
payload_wrapper.ParseFromString(base64.b64decode(encoded_payload))
# define the desired action type indicated by the payload
action = payload_wrapper.action
timestamp = payload_wrapper.timestamp
# used to determine which handler function should be used on a certain type of payload
TYPE_TO_ACTION_HANDLER = {
   Payload.CREATE_PROJECT: 'create_project',
   Payload.CREATE_TASK: 'create_task',
   Payload.PROGRESS_TASK: 'progress_task',
   Payload.EDIT_TASK: 'edit_task',
   Payload.ADD_USER: 'add_user'
}
try:
   # get the correct payload field and handler function from the action type
   attribute= TYPE_TO_ACTION_HANDLER[action]
   print(attribute)
except KeyError:
   raise Exception('Specified action is invalid')
# extract the correct payload based on the action type
payload = getattr(payload_wrapper, attribute)
print(payload)
