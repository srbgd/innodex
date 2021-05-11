from web3 import Web3
from time import sleep

w3 = None
WAITTIME = 1
RETRIES = 3

def failover(default=None):
    def decarator(f):
        def wrapper(*args, **kwargs):
            try:
                result = f(*args, **kwargs)
            except:
                result = default
            return result
        return wrapper
    return decarator

def get_w3():
    global w3
    if w3 is None:
        retries = 0
        success = False
        while not success and retries < RETRIES:
            try:
                w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:9545/'))
            except:
                pass
            else:
                success = w3.isConnected()
            if not success:
                retries += 1
                sleep(WAITTIME)
    w3.eth.default_account = w3.eth.accounts[0]
    return w3

@failover(default=dict())
def get_latest_block():
    return get_w3().eth.get_block('latest')

@failover(default=False)
def is_connected():
    return get_w3().isConnected()

@failover(default='')
def get_client_version():
    return get_w3().clientVersion

@failover(default=0)
def get_balance(address):
    return get_w3().eth.get_balance(address)

@failover(default=[])
def get_accounts():
    return get_w3().eth.accounts

@failover()
def get_origin_account():
    return get_w3().eth.default_account

def main():
    print(f'Is connected: {is_connected()}')
    print(f'Origin account: {get_origin_account()}')
    print(f'Origin balance: {get_balance(get_origin_account())}')
    print(f'Number of blocks: {get_latest_block().get("number")}')


if __name__ == '__main__':
    main()