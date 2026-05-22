These files were produced following https://childmindresearch.github.io/bids2table/bids2table.html docs

    b2t2 index -o openneuro.parquet -j 8 --use-threads s3://openneuro.org/ds*

and then renamed and also converted to .tsv using

    visidata -b derivatives/openneuro-all.parquet -o derivatives/openneuro-all.tsv

and renamed again into BIDS like convention and then renamed again to reflect
used by upstream `b2t2`, not `b2t`, and then redone renaming a bit for the sake
of cleanless... uff ;)
