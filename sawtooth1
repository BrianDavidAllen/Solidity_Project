import hashlib
import secp256k1
import time
import requests
import json


# Sawtooth SDK
from sawtooth_sdk.protobuf.transaction_pb2 import Transaction
from sawtooth_sdk.protobuf.transaction_pb2 import TransactionHeader
from sawtooth_sdk.protobuf.batch_pb2 import Batch
from sawtooth_sdk.protobuf.batch_pb2 import BatchHeader
from sawtooth_sdk.protobuf.batch_pb2 import BatchList

from protobuf.payload_pb2 import *
import addressing

def _get_batcher_public_key(signer):
    return signer.pubkey.serialize().hex()


def _get_time():
    return int(time.time())


def _create_signer(private_key):
    signer = secp256k1.PrivateKey(privkey=bytes.fromhex(str(private_key)))
    return signer
    

class Txn_Factory():
    def create_project(self, args):
        ''' Creates a transaction that includes a create_project payload

            args: [password/signer, project_name]
        '''
        if not len(args) == 2: # make sure correct number of arguments are present for desired transaction
            print("\nIncorrect number of arguments for desired command.\n")
            quit()
        signer = args[0]

        # bundle the action information
        action = CreateProjectAction(
                project_name = args[1],
        )
        # bundle the payload
        payload = Payload(
            action = 0,
            timestamp = _get_time(),
            create_project = action,
        )

        # serialize/encode before sending
        payload_bytes = payload.SerializeToString()

        # Pack it all up and ship it out
        txn = self.create_transaction(signer, payload_bytes)
        batch_list_bytes = self.create_batch(signer, txn)
        send_it(batch_list_bytes)

    def create_task(self, args):
        ''' Creates a transaction that includes a create_task payload

            args: [password/signer, project_name, task_name, description]
        '''
        if not len(args) == 4: # make sure correct number of arguments are present for desired transaction
            print("\nIncorrect number of arguments for desired command.\n")
            quit()
        signer = args[0]
        # bundle the action information
        action = CreateTaskAction(
                project_name = args[1],
                task_name = args[2],
                description = args[3]
        )
        # bundle the payload
        payload = Payload(
            action = 1,
            timestamp = _get_time(),
            create_task = action,
        )

        # serialize/encode before sending
        payload_bytes = payload.SerializeToString()

        # Pack it all up and ship it out
        txn = self.create_transaction(signer, payload_bytes)
        batch_list_bytes = self.create_batch(signer, txn)
        send_it(batch_list_bytes)

    def progress_task(self, args):
        ''' Creates a transaction that includes a progress_task payload
        

            args: [password/signer, project_name, task_name]
        '''
        if not len(args) == 3: # make sure correct number of arguments are present for desired transaction
            print("\nIncorrect number of arguments for desired command.\n")
            quit()
        signer = args[0]

        action = ProgressTaskAction(
                project_name = args[1],
                task_name = args[2],
        )
        # bundle the payload
        payload = Payload(
            action = 2,
            timestamp = _get_time(),
            progress_task = action,
        )
        
        # serialize/encode before sending
        payload_bytes = payload.SerializeToString()

        # Pack it all up and ship it out
        txn = self.create_transaction(signer, payload_bytes)
        batch_list_bytes = self.create_batch(signer, txn)
        send_it(batch_list_bytes)

    def edit_task(self, args):
        ''' Creates a transaction that includes a create_project payload

            args: [password/signer, project_name, task_name, description]
        '''
        if not len(args) == 4: # make sure correct number of arguments are present for desired transaction
            print("\nIncorrect number of arguments for desired command.\n")
            quit()
        signer = args[0]
        # bundle the action information
        action = EditTaskAction(
                project_name = args[1],
                task_name = args[2],
                description = args[3]
        )
        # bundle the payload
        payload = Payload(
            action = 3,
            timestamp = _get_time(),
            edit_task = action,
        )

        # serialize/encode before sending
        payload_bytes = payload.SerializeToString()

        # Pack it all up and ship it out
        txn = self.create_transaction(signer, payload_bytes)
        batch_list_bytes = self.create_batch(signer, txn)
        send_it(batch_list_bytes)

    def add_user(self, args):
        ''' Creates a transaction that includes an add_user payload

            args: [password/signer, project_name, public_key]
        '''
        if not len(args) == 3: # make sure correct number of arguments are present for desired transaction
            print("\nIncorrect number of arguments for desired command.\n")
            quit()

        signer = args[0]
        new_pass = args[2]
        priv_key = hashlib.sha256(new_pass.encode('utf-8')).hexdigest()
        args[2] = _create_signer(priv_key).pubkey.serialize().hex()

        # bundle the action information
        action = AddUserAction(
                project_name = args[1],
                public_key = args[2],
        )
        # bundle the payload
        payload = Payload(
            action = 4,
            timestamp = _get_time(),
            add_user = action,
        )

        # serialize/encode before sending
        payload_bytes = payload.SerializeToString()

        # Pack it all up and ship it out
        txn = self.create_transaction(signer, payload_bytes)
        batch_list_bytes = self.create_batch(signer, txn)
        send_it(batch_list_bytes)


    def create_transaction(self, signer, payload_bytes):
        '''Bundles together a transaction that includes the given payload and is signed by given signer'''
        txn_header_bytes = TransactionHeader(
            family_name='todo',
            family_version='0.1',
            inputs=[addressing.NAMESPACE],
            outputs=[addressing.NAMESPACE],
            signer_public_key = signer.pubkey.serialize().hex(),
            # In this example, we're signing the batch with the same private key,
            # but the batch can be signed by another party, in which case, the
            # public key will need to be associated with that key.
            # make a global batch_public_key
            batcher_public_key = signer.pubkey.serialize().hex(), 
            # must have been generated from the private key being used to sign
            #  the Batch, or validation will fail
            # In this example, there are no dependencies.  This list should include
            # an previous transaction header signatures that must be applied for
            # this transaction to successfully commit.
            # For example,
            # dependencies=['540a6803971d1880ec73a96cb97815a95d374cbad5d865925e5aa0432fcf1931539afe10310c122c5eaae15df61236079abbf4f258889359c4d175516934484a'],
            dependencies=[],
            payload_sha512=hashlib.sha512(payload_bytes).hexdigest()
        ).SerializeToString()

        # Ecdsa signing standard, then remove extra ecdsa bytes using compact.
        txn_signature = signer.ecdsa_sign(txn_header_bytes)
        txn_signature_bytes = signer.ecdsa_serialize_compact(txn_signature)
        signature = txn_signature_bytes.hex()

        txn = Transaction(
            header=txn_header_bytes,
            header_signature=signature,
            payload=payload_bytes
        )

        return txn;

    def create_batch(self, signer, txn):
        '''Bundles together a batch that includes txn and is signed by given signer'''
        batch_header_bytes = BatchHeader(
            signer_public_key = signer.pubkey.serialize().hex(),
            transaction_ids=[txn.header_signature],
        ).SerializeToString()

        batch_signature = signer.ecdsa_sign(batch_header_bytes)
        batch_signature_bytes = signer.ecdsa_serialize_compact(batch_signature)
        signature = batch_signature_bytes.hex()

        batch = Batch(
            header=batch_header_bytes,
            header_signature=signature,
            transactions=[txn]
        )

        batch_list_bytes = BatchList(batches=[batch]).SerializeToString()

        return batch_list_bytes


def send_it(batch_list_bytes):
   '''Sends batch to REST API, eventually reaching validator nodes and transaction processors'''
   # ship it out and scrape
   url = "http://bc.oregonctf.org:8008/batches"
   headers = { 'Content-Type' : 'application/octet-stream' }
   payload = batch_list_bytes
   resp = requests.post(url, data=payload, headers=headers)
   json_url = json.loads(resp.text)
   # print("Batch status link: \n\n" + json_url["link"] + "\n") # DEBUG
   resp = requests.get(json_url["link"])
   json_batch_status = json.loads(resp.text)
   status = json_batch_status["data"][0]["status"]
   print("PENDING")
   while not (status == "COMMITTED" or status == "INVALID"):
       resp = requests.get(json_url["link"])
       json_batch_status = json.loads(resp.text)
       status = json_batch_status["data"][0]["status"]
   print(status)

if __name__ == '__main__':
    txn_factory = Txn_Factory()

    args = sys.argv[1:]
    passcode = args[1]

    priv_key = hashlib.sha256(passcode.encode('utf-8')).hexdigest()
    args[1] = _create_signer(priv_key)
    # run desired function
    getattr(txn_factory, args[0])(args[1:])
