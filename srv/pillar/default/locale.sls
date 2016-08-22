# pillar locale

locale: 
  present:
    - "en_US.UTF-8 UTF-8"
    - "en_AU.UTF-8 UTF-8"  # replace with your own
  default: 
    name: 'en_AU.UTF-8' # Note: On debian systems don't write the 
                        # second 'UTF-8' here or you will experience 
                        # salt problems like:
                        # LookupError: unknown encoding: utf_8_utf_8
                        # Restart the minion after you corrected this!
    requires: 'en_AU.UTF-8 UTF-8'  # replace with your own