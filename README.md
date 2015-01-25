# attribute-validator-ng cookbook

A Chef cookbook that applies validation rules to the node attributes during a chef run or from your recipe.

# Why would I possibly want that?

Attribute merging is *hard*.  It's very easy to accidentally override something (in a role, node, environment, third-order-dependent cookbook....), or fat-finger a attribute name, or have a change in another cookbook stomp on your attributes.  I wanted something industrial-strength that would provide early warning when an attribute was missing, spurious, or had an incoherent value.

I also wanted a cookbook that cares about the validation to be able to define the rules in a simple way, and make it easy to have as much or as little validation as you want to implement.

# Usage

## Writing Rules via attributes

Basically, you define rules in node attributes.  A typical use case comes up when you're creating a new cookbook.  Naturally, you expose certain "knobs" as node attributes, which the user of your cookbook can set in any number of ways - application or wrapper cookbooks attribute files, roles, even environments.  You'd like to catch missing or invalid attribute values before you try to converge using them, and throw a meaningful error (something better than "No such method [] for nil:NilClass", for example).

So, to define rules, add a series of hashes in your cookbook attributes.  Each rule has a path, which optionally includes wildcards; the path is then used to select which attributes to apply the rule's checks.  Checks include things like type, presence, regex, and so one.

Here is how to make sure that your feature flags really are booleans, and not 0, 1, "true", etc.

     default['attribute-validator-ng']['rules']['some-rule'] = {
        'path' => '/my-cookbook/feature_*/enabled',
        'type' => 'boolean'
     }

Once you defined your attributes, you need add one of the recipes to your runlist or including them explicitely into your recipe.


## Enforcing rules via recipes

Another way to enforce attribute validation is to do it inside your cookbook's recipe without the need to specify global attributes under node['attribute-validator-ng']['rules']:

    # recipe:: default.rb

    rules = {}
    rules['some-rule'] = {
        'path' => '/my-cookbook/feature_*/enabled',
        'type' => 'boolean'
    }

    Chef::Attribute::Validator.validate rules

    ... rest of the recipe ...


# Attributes

Rule definitions, if you want to use the runlist behaviour, occur under default['attribute-validator-ng']['rules'][...] like this:

     default['attribute-validator-ng']['rules'][some-rule] = {
        'path' => '/my-cookbook/feature_*/enabled',
        # Checks like type, regex, looks_like, min_children, present, etc
        ...
     }

     default['attribute-validator-ng']['rules'][another-rule] = { ... }

The cookbook also exposes a few settings of its own:

      default['attribute-validator-ng']['fail-action'] = 'error'

The default is 'error', which will raise an exception if any violations are found, halting the chef run.  You may also provide 'warn', which will issue a warning to the chef log for each violation found, but allow the run t continue.

## Rule attributes

### path - Required

Slash formatted path of the attributes to check.

Attribute locations are described using a syntax similar to shell globs.

Given:

     /foo         - Matches exactly node['foo']
     /foo/bar     - Matches exactly node['foo']['bar']
     /foo/*       - Matches for example node['foo']['bar'] and node['x']['baz']
     /foo/**/xyz  - Matches for example node['foo']['a']['b']['c']['xyz']

### enabled

Optional boolean, default true.  Set to false to knock out rule.

### child_keys

Checks the immediate keys of the given path (which must be a Hash).  Check argument may be an Array of Strings, in which case each key that is present must be in the list of valid keys, or else a Regexp, which will be matched against each key.

### type

Checks type of value.  One of 'string', 'integer', 'float', 'number', 'boolean', 'hash', 'array'.

### min_children

Integer.  Fails for all but Hash and Array.  For Hash and Array, minimum number of elements to be considered valid.

### max_children

Integer.  Fails for all but Hash and Array.  For Hash and Array, maximum number of elements to be considered valid.

### present

Boolean.  If true, fails if the path matches zero attributes.  If false, fails if the path matches nonzero attributes.  This is most useful for enforcing deprecated attributes.  Does not consider nilness, only existence of attribute key(s).  See also required.

### regex

Regexp.  Applies given regex to the value.  Ignored for Hash and Array.  See looks_like for a selection of canned regexen.

### required

Boolean.  If true, fails if the path matches zero attributes, or the value is nil, or the value is the empty string, or if the value is an empty array or empty hash.  No-op if false (use present => false to enforce absence).

### looks_like

String, one of 'email', 'guid', 'hostname', 'ip', 'url'.  Applies canned regexes (or more sophisticated matchers, like constructing objects from the stdlib).  Details:

#### email

Uses a naive regex to do a simple sanity check.  It may be too tight or too loose for you, in which case you can use a Proc and spend as much of your energy as you please solving that problem.

#### guid

Uses a regex to match GUID/UUIDs, like 'ec73f2a8-510d-4e6a-be5d-7b234da03c92'

#### hostname

Uses a regex to guess if it looks hostnamish.  Does not require a dot.  Accepts IPv4, and checks ranges.

#### ip

Uses the stdlib 'ipaddr' library to try to construct an IPAddr object from the value.  If it worked, it's an IP.  IPv6 is supported; ranges are checked; CIDR notation is supported; and no you can't pass a hostname to this.

#### url

Uses the stdlib 'url' library to try to construct an URI object from the value.  If it worked, it's an URL.  This is probably too loose; it will accept bare hostnames, for example.

### enum

Array, a set of possible values.

### proc

A Proc, which will be evaluated to determine the validity.  The proc should take two args - a string rule name, and a Chef::Attribute::Validator::AttributeSet.  You can treat the attribute set as a hash - its each() methods will yield path, value pairs.
The proc should return a possibly empty array of Chef::Attribute::Validator::Violations.

## Referencing Attributes


# Recipes

## attribute-validator-ng::default

Alias of the converge-time-check recipe.

## attribute-validator-ng::compile-time-check

Calls the install recipe, then calls validate_all at compile time; if nonzero violations are found, throws an exception, which halts the run.

## attribute-validator-ng::converge-time-check

Calls the install recipe, then calls validate_all at convergence time (inside a ruby block); if nonzero violations are found, throws an exception, which halts the run.

# Bugs, Limitations, Misfeatures, Whinges, Roadmap

## Reporting Issues

Please report issues by opening a github issue at https://github.com/peick/attribute-validator-ng .  You're a thorough person who knows how important it is to give back to the community, so of course you'll be sending along a pull requst with a failing test, and another pull request with a fix.  That's just who you are, you're not bragging.

## Outstanding Bogs

None known.

## Roadmap

### Add support for reading rules from metadata.rb attribute DSL entries

Because nothing enforces that now.

### Handler support?

Add support for sending violations via a handler, to ... somewhere?

# Author

* Michael Peick
* Clinton Wolfe: this cookbook is a fork of https://github.com/clintoncwolfe/attribute-validator .

## Contributing

1. Fork it (https://github.com/peick/attribute-validator-ng)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request at (https://github.com/peick/attribute-validator-ng)
