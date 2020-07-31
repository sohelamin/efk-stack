# EFK Stack
> Getting ready with EFK stack

## Setup
1. Setup the main EFK Stack on a linux server using the shell script.
    ```
    sudo chmod +x EFK.sh
    ./EFK.sh
    ```

2. Visit your kibana dashboard and create `fluentd-*` index pattern in Management->Stack Management->Index Patterns.

3. Collect your log from your applicatiion. eg. for Node.js app you can use this [package](https://github.com/fluent/fluent-logger-node).

4. You can see the logs on kibana dashboard now.


### Security
To protect the kibana dashboard you can use the `htpasswd` in nginx.
Use authentication while communicating through fluentd.

### Extra commands

Delete indices from Elasticsearch
```
curl -XDELETE 'http://localhost:9200/logstash-*'
```
Check the space usage in Elasticsearch
```
curl -XGET 'http://localhost:9200/_cat/indices?v'
curl -XGET 'http://localhost:9200/_cat/allocation?v'
```

## Author

[Sohel Amin](http://sohelamin.com)
