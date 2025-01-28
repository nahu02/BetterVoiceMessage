import os

from dotenv import load_dotenv
import ell

load_dotenv()
store_location = os.getenv("ELL_STORE")

if store_location:
    ell.init(store=store_location, autocommit=True, verbose=True)
else:
    ell.init(verbose=True)
