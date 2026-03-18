DTC_VERSION = 0.2.14
DTC_INDEX = https://hub.psychoinformatics.de/datalink/dump-things-pyclient

UVX = uvx --from 'dump-things-pyclient==$(DTC_VERSION)' --extra-index-url $(DTC_INDEX)

.PHONY: fetch
fetch:
	$(UVX) ./fetch
