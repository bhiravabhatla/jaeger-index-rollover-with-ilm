# jaeger-index-rollover-with-ilm
Use ILM to manage jaeger indices.

####credits:
 https://github.com/jaegertracing/jaeger/blob/master/plugin/storage/es/esRollover.py
 https://github.com/pavolloffay
 
 This repo is an extension on work done by Pavol Loffay for managing jaeger indices.
 
 ---
 
 ###Problem Statement
 By default, Jaeger is configured to create one index per day and this might lead to uneven resource distribution. For example, few indices might contain significantly more data compared to others.
 ###Existing Solution for this
  Jaeger can be configured to start using aliases instead of standalone indices to read and write from. Rollover of indices and cleanup of older indices can be achieved using esRollover and esCleaner scripts which use Elasticsearch rollover endpoint (explained in detail in this blog by Pavol Loffay.
 What are we trying to achieve
 The catch with above approach is that we need to have a cronjob which runs esRollover and esCleaner scripts   regularly and performs rollover & cleanup based on the condition specified. 
 In this repo we try to use Elasticsearch ILM to perform rollover and cleanup actions automatically - instead of manually doing it by calling rollover API repeatedly. ILM performs the rollover in a clean and safer way.
 
 --
 
 To make Jaeger work with ILM , we can modify the jaegertracing/jaeger-es-rollover:latest image a bit and create overriding index templates for span & service indices which would add ILM policy & read-aliases to the indices. We would also add is_write_index: true to the initial indices. Details of which are explained below.
 
 ###Configuration
 * Before we setup jaeger, we would need to create a ILM in Elasticsearch with name "jaeger-ILM-Policy". The lifecycle policies can be defined as per user requirements. For demo purposes, we can use below ILM policy as a sample.
 
 ```PUT _ilm/policy/jaeger-ILM-Policy
 {
   "policy": {
     "phases": {
       "hot": {
         "min_age": "0ms",
         "actions": {
           "rollover": {
             "max_age": "1m"
           },
           "set_priority": {
             "priority": 100
           }
         }
       },
       "delete": {
         "min_age": "2m",
         "actions": {
           "delete": {}
         }
       }
     }
   }
 }
```
 
 `Note: By default, indices.lifecycle.poll_interval is set to 10m, but for testing we would have to set it to something shorter, say 10s, by running below in Elasticsearch.`
 
 ```PUT /_cluster/settings?flat_settings=true
 {
   "transient": {
     "indices.lifecycle.poll_interval": "10s"
   }
 }
```
 *  Run init to create initial set of indices, index templates and aliases (assuming Elasticsearch is running on localhost)
 ```
 docker run -it --rm --net=host bhiravabhatla/jaeger-es-rollover-init:1.0 init http://localhost:9200 "jaeger-ILM-Policy"
 ```

 This script creates two sets of aliases for span and service indices: jaeger-span-write, jaeger-span-read, jaeger-service-write,  jaeger-service-read. When we run Jaeger with  --es.use-aliases=true flag it always writes spans to jaeger-span-write alias and service/operations to jaeger-service-write. Similarly, Jaeger always reads from the corresponding read aliases.
 
 ###Changes made to original script
 
 One change that's made to esRollover script is to configure {'is_write_index':True} setting while adding write alias to the initial set of indices (jaeger-span-000001 & jaeger-service-000001).
 This is done to make ILM manage the indices properly - when rollover conditions are met, ILM automatically removes {'is_write_index':True} from rolled-over index and adds it to the newly created index (more about it here).
 
 https://github.com/bhiravabhatla/jaeger-index-rollover-with-ilm/blob/d8253037267914ba8f745c8c0aa4b1e0f0167022/esRollover.py#L125

 Another change made was to create override index templates, which would attach ILM policy using jaeger-span-write/jaeger-service-write as the ILM rollover_alias for span & service indices respectively. 
 This index template also adds the jaeger-span-read/jaeger-service-read alias to all span/service indices - so that jaeger is able to read from all the indices.
 
 https://github.com/bhiravabhatla/jaeger-index-rollover-with-ilm/blob/master/mappings/jaeger-span-with-ilm-7.json
 
* Finally run Jaeger with --es.use-aliases=true flag.
 docker run -it --rm --net=host \
   -e SPAN_STORAGE_TYPE=elasticsearch \
   jaegertracing/all-in-one:latest \
   --es.use-aliases=true \
   --es-archive.enabled=true \
   --es-archive.use-aliases=true
 You should be able to see new indices getting created every minute and older indices getting deleted 2 mins after rollover. Jaeger should be able to read from all the non-deleted indices.
 
 
### Local development

To build image:

```
make build
```

To publish, increment the version and

```
make publish
```