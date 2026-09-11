DTC_VERSION = 0.3.0
DTC_INDEX = https://github.com/ORINOCO-Lite/dump-things-pyclient

UVX = uvx --from 'dump-things-pyclient==$(DTC_VERSION)' --extra-index-url $(DTC_INDEX)

.PHONY: fetch
fetch:
	$(UVX) ./fetch
