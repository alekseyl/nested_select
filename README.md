# WIP disclaimer
I'm currently extracting nested_select functionality from the brest gem, including tests, and minor fixes. 

# Nested select -- 7 times faster and 33 times less RAM on preloading relations with heavy columns!
nested_select allows to select attributes of relations during preloading process, leading to less RAM and CPU usage.
Here is a benchmark output for a [gist I've created](https://gist.github.com/alekseyl/5d08782808a29df6813f16965f70228a) to emulate real-life example

Relations has a following structure: 
Course has many topics, each topic has many lessons. 
To display a single course you need its structure, minimum data needed is set of topic and lessons titles and ordering.

**Single course**, a real prod set of data used by current UI (~ x33 times less RAM):

```
irb(main):216:0>compare_nested_select(ids, 1, silence_ar_logger_for_memory_profiling: false)

------- CPU comparison, for root_collection_size: 1 ----                                                           
       user     system      total        real                                                                      
nested_select  0.096008   0.002876   0.098884 (  0.466985)                                                         
simple includes  0.209188   0.058340   0.267528 (  0.903893)                                                       
                                                                                                                   
----------------- Memory comparison, for root_collection_size: 1 ---------                                         

D, [2025-01-12T19:08:36.163282 #503] DEBUG -- :   Topic Load (4.1ms)  SELECT "topics"."id", "topics"."position", "topics"."title", "topics"."course_id" FROM "topics" WHERE "topics"."deleted_at" IS NULL AND "topics"."course_id" = $1  [["course_id", 1624]]                                                                 
D, [2025-01-12T19:08:36.168803 #503] DEBUG -- :   Lesson Load (3.9ms)  SELECT "lessons"."id", "lessons"."title", "lessons"."topic_id", "lessons"."position", "lessons"."topic_id" FROM "lessons" WHERE "lessons"."deleted_at" IS NULL AND "lessons"."topic_id" = $1  [["topic_id", 7297]]                                      
D, [2025-01-12T19:08:37.220379 #503] DEBUG -- :   Topic Load (4.2ms)  SELECT "topics"."id", "topics"."position", "topics"."title", "topics"."course_id" FROM "topics" WHERE "topics"."deleted_at" IS NULL AND "topics"."course_id" = $1  [["course_id", 1624]]                                                                 
D, [2025-01-12T19:08:37.247484 #503] DEBUG -- :   Lesson Load (25.7ms)  SELECT "lessons".* FROM "lessons" WHERE "lessons"."deleted_at" IS NULL AND "lessons"."topic_id" = $1  [["topic_id", 7297]]

------ Nested Select memory consumption for root_collection_size: 1 ------                                         
Total allocated: 80.84 kB (972 objects)
Total retained:  34.67 kB (288 objects)

------ Full preloading memory consumption for root_collection_size: 1 ----
Total allocated: 1.21 MB (1105 objects)
Total retained:  1.16 MB (432 objects)
RAM ratio improvements x33.54678126442086 on retain objects
RAM ratio improvements x15.002820281285949 on total_allocated objects
```

**100 courses**, this is kinda a synthetic example (there is no UI for multiple courses display with their structure) 
on the real prod data, but the bigger than needed collection ( x7 faster):

```
irb(main):280:0> compare_nested_select(ids, 100)

------- CPU comparison, for root_collection_size: 100 ----
       user     system      total        real           
nested_select  1.571095   0.021778   1.592873 (  2.263369)
simple includes  5.374909   1.704284   7.079193 ( 15.488579)
                                                        
----------------- Memory comparison, for root_collection_size: 100 ---------
------ Nested Select memory consumption for root_collection_size: 100 ------

Total allocated: 2.79 MB (30702 objects)                
Total retained:  2.05 MB (16431 objects)                

------ Full preloading memory consumption for root_collection_size: 100 ----

Total allocated: 33.05 MB (38332 objects)               
Total retained:  32.00 MB (24057 objects)               
RAM ratio improvements x15.57707431190517 on retain objects
RAM ratio improvements x11.836000856510193 on total_allocated objects

```

# A little bit of nested_select history
Awhile ago I investigated the potential performance boost from partial instantiation 
of database records in rails applications: [Rails nitro-fast collection rendering with PostgreSQL](https://medium.com/@leshchuk/rails-nitro-fast-collection-rendering-with-postgresql-a5fb07cc215f)

To be short among the others I've tested the idea of Partial instantiation:

> Sometimes different actions needs different set of columns per ORM object. You can speedup instantiation 
> by creating sets of attributes specific for particular request. 
> It can be done through the scopes and scoped relations inside your model.

**Pluses**
> It may be faster. How fast? Highly depends on data structure and ratio of used columns. I started from instantinating 75% of object columns and go to 1 or 2 columns being instantiated. 
> In terms of instantiation results are: 1.3–4.2 times faster on simple type columns ( text, string, int, bool etc.), and 1.2–10 times faster when you exclude json/jsonb/store instantiation. 
> Also all this numbers received without any instantiation callbacks like after_find.

Also during my investigations I've kinda missed to mention the other aspects of the problem: RAM, DB IOps, network throughput.
Requesting less columns improves¹ all that things. 

But that's a pretty obvious. There are lot of articles covering this problem an idea of partial selection:

ActiveRecord select :id column over 1000 records in a different way:
https://samsaffron.com/archive/2018/06/01/an-analysis-of-memory-bloat-in-active-record-5-2

Just another simple and newbie technics on boosting ActiveRecord ( including partial selection ):
https://medium.com/@snapsheetclaims/11-ways-to-boost-your-activerecord-query-performance-32b9986f093f

Just partial selection article: 
https://pawelurbanek.com/activerecord-memory-usage

And others.

But the real problem is: **in rails you can't do any selection on preloading models** (until nested_select of course :)) ).
Ths means that all that tree of preloaded object goes with ```SELECT table_name.*``` query.

Technically speaking you may solve this problem by defining custom scopes and defining custom tailored relation with scopes. 
But that's a lot of a boilerplate code, creating scopes and nested relations for all kinds of requests looks like unreal solution, 
no one will do such madness.

[1] I have much less idea on how other than PotsgreSQL DB-engines are working with a disk in terms of partial tuples/records reading. 
Postgres itself will read a whole page from a disk to retrieve the record, but then lesser columns could switch retrieval to an Index-Only scan decreasing IOps significantly


## Nested Select patch

### How preloading happens in rails and when is the best time to interfere

**Preloading** is a part of activerecord which tends to change pretty often.
Practically all major releases interfere preloader code, the current implementation was introduced starting rails 7.0 version.
But if you get the idea of current implementation, you can traverse the earlier state and get the idea how to make them work with nested select:
Regardless of the major rails version and implementation, you will end up patching the `build_scope` method of
`ActiveRecord::Associations::Preloader::Association`!

So you just need to define a way to deliver select_values to instance of `ActiveRecord::Associations::Preloader::Association`

### How preloading happens in rails >= 7.0
To be honest ( and opinionated :) ), current preloading implementation is a kinda mess, and we need to adapt to this mess without delivering some more.

Let's look at the scopes example from a specs:
```ruby
# user <-habtm-> bought_items
# user -> has_one -> user_profile -> has_many -> avatars
User.includes( :bought_items, user_profile: :avatars)
```

Preloading will create instances `Preloader` objects for:
- each isolated preloading `Branch` which started from the root, in this case: `:bought_items` and `user_profile: :avatars`
- each trough relation inside preloading tree, including hidden ones like habtm relation does.

Each `Preloader` object building it's own preloader tree from a set of `Branch` objects.
In a given case it might roughly look like this:
```
Preloader(:bought_items) -> Branch(:root) 
                              \__ Branch(:bought_items) -> Preloader::ThroughAssociation(:bought_items)
                              
Preloader(user_profile: :avatars) -> Branch(:root) 
                                        \__ Branch(:user_profile) -> Preloader::Association(:user_profile)
                                              \__Branch(:avatars) -> Preloader::Association(:avatars)                          
```

Each `Branch` will create a set of loaders objects of `Preloader::Association` or `Preloader::ThroughAssociation`
Then running all of them will preload nested records and establish a connections between records.

To be able to select limited attributes sets, we need to deliver them to `Association` level objects, and patch `build_scope` method with it.

**_Rem:_** Each `Preloader::ThroughAssociation` object creates it's own `Preloader` and starts additional 'isolated' preloading process.

So implementation adds a `nested_select_values` attributes into instances of `Preloader`, `Branch`, `Association` hierarchy and some methods to populate corresponding select_values over the tree.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add nested_select

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install nested_select

## Usage

```ruby

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nested_select. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the NestedSelect project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/nested_select/blob/master/CODE_OF_CONDUCT.md).
