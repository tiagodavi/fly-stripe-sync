1 - First thing I did was read the entire README, then I made sure to keep the README open to follow instructions.

2 - I took a look at the entire codebase in order to understand it.

3 - I noticed there is a scalability issue because calling Stripe "aggressively" is not a healthy strategy.

4 - I noticed there is a rate limit on Stripe APIs, and it makes total sense, but the system must operate under this constraint.

5 - Users may end up with limited usage info when there are failed synchronizations with Stripe, and this might force them to look for competitors instead of using Fly.io.

6 - The company can't be paid for the invoice that has been delayed due to technical issues.

7 - I drew all the system components on Figma, such as Invoice, InvoiceItem, Organization, Stripe and their properties to have a "big picture" of the entire system.

8 - I cloned the repo and ran the application, I also took a look at the sample data on Postgres.

9 - Compiling usage data internally and generating invoices in real-time sounds like a more efficient idea because it will avoid calling Stripe aggressively and yet will provide all the usage data the user needs to know in order to pay their invoice at the end of the billing cycle.

10 - Given that the technology is Elixir, I decided to install the Broadway library to solve this problem.The idea is to collect all usage data from queues where we have the flexibility to use any Amazon SQS, Kafka, RabbitMQ, etc. With the data in hand, we can spawn processes to generate multiple InvoiceItems that are linked to an Invoice that is not yet due. This approach brings flexibility and can scale easily in a distributed system.

11 - In terms of 'big customer-facing ideas,' I would use LiveView because we can easily connect the usage data with Live Processes and display the data in real-time for the users. It will give them a much better experience.

12 - To run this app in production, I would create a release of it and send it to a Fly.io instance.
It's important to have the system that collects usage data sending events to the queues as well.

13 - In order to maintain confidence that the system is working, we can use monitoring tools such as New Relic and App Signal, and make sure the entire stack, integrations, and pipelines are covered for tests.

14 - I don't think it is a good strategy to display errors for users on this system because it is related to usage data and billing, and it may raise concerns for users who trust the system. Instead, I think we should display the last available usage information and show a message that says the billing service is experiencing issues, with a deadline for fixing it. The company can also share a link with the clients that displays the status of each system.

15 - I decided to hide technical errors from the users, specifically for this system, because it is related to billing and may cause unwarranted concerns and biases. Instead, I chose to communicate that there's a problem without specifying the exact nature of the problem to avoid those concerns.

I decided to use a simple GenServer scheduler to close invoices. However, this is not the best approach because it could start duplicate processes in a distributed system with multiple nodes and run the scheduler once for each node. To mitigate we could use Oban or some powerful scheduler. Nevertheless, this simple one helps us start and keep things simpler for now.

I decided to use Mimic to have a more powerful way to mock Stripe in concurrent mode.
https://github.com/edgurgel/mimic

16 - I would include the UI part with LiveView in the next iteration of this feature so we could have something visually available.

17 - I would implement handling failed messages better to ensure all messages are successfully processed, even the failed ones (eventually). I would also add more unit tests to cover additional edge cases, as well as integration tests in a mock instance running with some real queues.

To execute the code in dev / prod environment follow the instructions bellow:

```elixir
[producer] = Broadway.producer_names(Fly.Stripe.SyncService)

{:ok, organization} =
    Fly.Organizations.create_organization(%{
        name: "Fly branch",
        stripe_customer_id: "fly_stripe_customer_id"
    })

message = %{
    "organization_id" => organization.id,
    "stripe_customer_id" => organization.stripe_customer_id,
    "description" => "Usage data",
    "amount" => 42,
    "unit_amount_decimal" => 2.5,
    "quantity" => 20
}

Fly.Stripe.EventSimulator.push(producer, message)

Fly.Billing.list_invoices()
```
