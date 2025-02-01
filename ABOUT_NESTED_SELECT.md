# A little bit of nested_select history
Awhile ago I've investigated the potential performance boost from partial instantiation 
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

[1] I have much less idea on how other than PotsgreSQL DB-engines are working with a disk in terms of partial tuples/records reading.
Postgres itself will read a whole page from a disk to retrieve the record, but then lesser columns could switch retrieval to an Index-Only scan decreasing IOps significantly

But that's a pretty obvious. There are lot of articles covering this problem and idea of a partial selection:

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

## Nested Select patch

### How preloading happens in rails and when is the best time to interfere

**Preloading** is a part of activerecord which tends to change pretty often.
Practically all major releases interfere preloader code, the majority of current implementation was introduced in the rails 7.0 version.
But if you get the idea of current implementation, you can traverse the earlier state and get the idea how to make them work with nested select:
Regardless of the major rails version and implementation, you will end up patching the `build_scope` method of
`ActiveRecord::Associations::Preloader::Association`!

So you just need to define a way to deliver select_values to instance of `ActiveRecord::Associations::Preloader::Association`

### How preloading happens in rails >= 7.0
To be honest ( and opinionated :) ), current preloading implementation is messy, 
and we need to adapt to this mess without delivering some more.

Let's look at the scopes example from a specs:
```ruby
# user <-habtm-> bought_items
# user -> has_one -> user_profile -> has_many -> avatars
User.includes(:bought_items, user_profile: :avatars)
```

Preloading will create instances of the `Preloader` class for:
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

The implementation of nested_select adds a `nested_select_values` attributes into instances of `Preloader`, `Branch`, `Association` hierarchy 
and some methods to populate corresponding select_values over the tree, trying to be as less invasive as it could be.
