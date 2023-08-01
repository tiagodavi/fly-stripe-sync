# Fly Backend Work Sample

Hello! This is a hiring project for our [Full-Stack Engineer position](https://fly.io/jobs/full-stack-engineer/).
If you apply, we’ll ask you to do this project so we can see how you work through a contrived (yet shockingly accurate) example of the type of things you’d do at Fly.io.

We want you to write some code to solve this problem, and tell us about your solution in the `NOTES.md` file. More details below!

## The Job

As a Full-Stack Engineer at Fly.io, you’ll be working on the interfaces around our platform product. Checkout the [job post](https://fly.io/jobs/full-stack-engineer/) for the nitty gritty.

## Background Information

We have a few apps that handle our infrastructure. Some are Phoenix (Elixir), and some are Rails (Ruby). 
Going forward, we expect to add new features primarily in a Phoenix app. One important thing our backend does is
take care of billing and invoicing:

* Handles billing for a bunch of different things. Invoices are a combination of metered product usage, one-off line items, and recurring subscription fees.
* Generates 10s of thousands of invoices each month.
* Models our global account data with concepts like `Organizations` and `Users`.
* Syncs data to Stripe, our payment processor, so we can bill developers for their usage.

Our current process for billing developers looks like this: we sync usage data from a variety of sources to Stripe, which generates an invoice based on Stripe's knowledge of our products and pricing.
The challenge is that we bill for a whole lot of things in tiny increments, so we need to sync usage data to Stripe _all the time_.

We sync to Stripe so aggressively that we sometimes fail to sync at all, which means we can't tell our users how much they owe.

This strategy of aggressively pushing usage data to Stripe reduces our ability to provide a good developer experience.

## Your task - the code

**We want you to build a better system to sync billable usage to Stripe.** We need an implementation 
that does not aggressively sync to Stripe, and ultimately gives the developer a good experience.

We also don't want to waste your time, so we've provided you with some code to get you started. You're allowed to make any 
changes you want, to any of the code we've written -- nothing is off-limits.  Check out the 
[code we've provided you section](#code-weve-provided-you) for more information. 

We're not trying to box you in to a particular solution. If you feel like something is in the way or doesn't make sense, just change it or get rid of it!


## Your task - the notes

`NOTES.md` is a place for you to show us how you think about the problem and what you'd be thinking about if you were in 
charge of this feature at Fly.io. Even though this project does not have a UI component, we're especially interested in 
how you think the billing experience should work for developers using Fly.io. We want to see you approach the exercise in 
a way that prioritizes the needs of our users.

Here are some examples of things we love reading in peoples' `NOTES.md` files:


* What big customer-facing ideas would you focus on to improve their experience around usage and billing?
* How would you run the Stripe sync in production? How do we maintain confidence that this sync continues to work?
* How would you communicate errors and problems to the user?
* What tradeoffs did you make in your solution? How does this tradeoff impact the user? Why did you make the decision you made? 
* What would you include in the next iteration of this feature?
* If you wanted to implement something, but didn't have time for it, tell us about it, and why it was important.
* Any other comments, questions, or thoughts that came up.

## Tips, more information, etc.

### What we're looking for

We want to see two things:

1. **You can write some Elixir code to solve a real life problem** (in particular, sending invoices to Stripe).
2. **You're always thinking about the user.** This should show up in decisions you make in the code, as well as in the Notes! 

That is really it. And we're really more focused on (2) than (1) here. (Protip: your notes are important and can make up 
for some issues in your code.)

One more tip: we care _a lot_ about scope. You might be tempted to try and solve the whole big problem, but that's not 
what we want for this exercise. We're asking for focused work. "Background Information" is just that. We want to help 
you understand the problem. We're not asking you to do extra work.

### Don't do this

There's a lot of extra work you'd do in real life that we don't need to see here. Feel free to skip these things:

* Don't spend time making this perfect or writing tests for every scenario.
* Don't solve every edge case. Rough edges are fine if it helps you move quickly, and you can document your decisions and trade-offs in NOTES.md.
* In real life, there's probably a lot more database schema. Don't worry about real life, just worry about what we're asking for.
* Skip quality of life improvements. We're wary of code coverage tools, refactors, testing library changes, etc. We definitely don't want you to spend time on that stuff.

**_And last, if you know what you're doing, don't spend more than two hours writing the code._** If you are learning, take all the time you need. But if you're experienced with Phoenix (Elixir), databases, and data consistency issues, this should be a quick project.

### Code we've provided you

This section describes the code we wrote for you in this project. Remember that you're allowed to change anything here, 
this is just a starting point!

#### How we're thinking about solving the problem

To solve this, we were thinking that we could compile our own usage data and generate invoices in real-time.

Once an invoice is generated, we can sync the invoice, rather than the usage, to Stripe and use that to bill our customers.

#### Models/schema

We created some invoice models and migrations for you.

In particular, we have:

* `Invoice` - this is the top-level invoice which we'll use to bill developers monthly.
* `InvoiceItem` - this is a line item that belongs to an invoice. It can represent metered product usage,
a one-off fee, or a recurring subscription fee.
* `Organization` - this represents the entity that gets invoiced.

Here are the relevant files:

* [Billing context](lib/fly/billing.ex)
* [Invoice schema](lib/fly/billing/invoice.ex)
* [InvoiceItem schema](lib/fly/billing/invoice_item.ex)
* [Organizations context](lib/fly/organizations.ex)
* [Organization schema](lib/fly/organizations/organization.ex)

#### Mock Stripe library

We've provided you with a mock Stripe library, so you don't need to waste time learning the Stripe API  or 
[Elixir's defactor Stripe library](https://github.com/beam-community/stripity-stripe). This is intended to make your
life easier - only use it if you want to!

In this library we've given you:

* functions to support CRUD operations for Stripe invoices and invoice items
* some stub functions to test out error and poor performance conditions

We wrote a lot more details and some examples in the mock library: [lib/fly/stripe.ex](lib/fly/stripe.ex).

#### Seeds (sample data population)

We've written a basic script for seeding data in our database, so you don't have to waste time on this. It's in
[priv/repo/seeds.exs](priv/repo/seeds.exs). 

### Install & Setup

#### Install Elixir (and Erlang)

If you don't have Elixir running locally already, we've left some instructions in [INSTALL.md](/INSTALL.md).

#### This app uses Postgres

Postgres is the default database that Phoenix uses. You'll need to have it installed locally to run the app. One way you
could do this is by running it in Docker:

```bash
docker run -d -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres
```

#### Getting the app running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
    - `setup` is defined in `mix.exs` under the `alias` function if you're curious what it's doing
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

#### Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

