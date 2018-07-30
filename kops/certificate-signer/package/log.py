import logging, os

logger           = logging.getLogger("operator")
streamHandler    = logging.StreamHandler()
streamHandler.setLevel(logging.DEBUG)
formatter        = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
streamHandler.setFormatter(formatter)
logger.addHandler(streamHandler)