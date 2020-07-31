# DependencyBumper

Dependency Bumper is a simple tool helps you to automate updating dependencies of your Ruby project.

## Usage

- Add dependency_bumper to your dependencies
- Go to your project's directory in terminal and write `dbump bump_gems` . It will update gems with default configuration.
- `dbump help bump_gems` will give you arguments for the command. This is the only command!
- You can also integrate dependency bumper to your program by simply calling `Updater.new(config).run`

## Configuration

You can tune behaviour of dependency bumper with configuration, it will run with default configuration if not specified

### Example configuration file

By default it will look for a file called `.bumper_config.json"` but you can specify config file as you wish. (Check `dbump help bump_gems`)

```json
{
    "skip": {
        "thor": true,
        "parslet": true
    },
    "outdated_level": "strict",
    "update": {
        "default": "minor",
        "major": { "console" : true },
        "minor": { "active_record": true, "async": true },
        "patch": { "rails": true }
    }
}
```

`outdated_level` = By default dependency_bumper only lists newer versions allowed by your Gemfile requirements. Other values `("major", "minor", "patch")` .

`update.default` = Default update level. You can easily tune this behaviour specific to gems. In example above, `console` gem will be updated next major version meanwhile `rails` gem will be only patch levels updates will be applied. All other dependencies will get `minor` level updates.

#### Default config

```
{
    "skip": { },
    "outdated_level": "strict",
    "update": {
        "default": "minor",
        "major": { },
        "minor": { },
        "patch": { }
    }
}
```

### Integration with git

```dbump bump_gemps --git``` command will create another branch (i.e "08-09-2020"), update your dependencies and and commit changes. Commit message body will include details of your update. I.e,

```
  gem-bump-08-09-2020

  parslet From 1.8.2 To 1.8.3 update level: patch
  thor From 0.20.3 To 1.0.0 update level: major
  zeitwerk From 2.3.0 To 2.4.0 update level: patch
```

### Similar projects

- https://github.com/mvz/keep_up
- https://github.com/attack/lapidarist
- https://github.com/wemake-services/kira-dependencies
- https://github.com/singlebrook/bunup
- https://github.com/dependabot/dependabot-core/tree/main/bundler/lib/dependabot/bundler

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing ٩(◕‿◕｡)۶

Bug reports and pull requests are welcome on GitHub at https://github.com/spandx/dependency_bumper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/dependency_bumper/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).
