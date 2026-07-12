# DO4DS: Lab Solutions

A practical guide to DevOps for data science. These labs cover the infrastructure and deployment practices that let data scientists ship models to production and keep them running reliably.

## What's in this book

I built these labs because most data science education stops at the model. You learn to train, validate, and tune, but then what? Deploying to production introduces a new set of challenges: building APIs, managing dependencies, automating deployments, securing servers, and monitoring systems. These labs are designed to fill that gap.

The book is organized into twelve labs, each building on the previous one:

- **Lab 1: Basic Models** — Start with Python and R data analysis, establishing the foundation for everything that follows.
- **Lab 2: Versioning Models** — Learn vetiver, the framework for versioning and deploying machine learning models.
- **Lab 3: Building APIs** — Create FastAPI (Python) and Plumber2 (R) APIs that serve your models as web services.
- **Lab 4: Logging and Monitoring** — Add instrumentation to your APIs so you can see what's happening in production.
- **Lab 5: CI/CD Automation** — Use GitHub Actions to automatically test and deploy your code on every push.
- **Lab 6: Containerization** — Package your APIs in Docker containers for consistent, portable deployments.
- **Lab 7: Cloud Infrastructure** — Deploy to AWS, store model artifacts in S3, and automate publishing with GitHub Actions.
- **Lab 8: Remote Access** — Connect securely to cloud instances using SSH and understand public-key authentication.
- **Lab 9: User Management** — Manage system users and permissions on Linux servers.
- **Lab 10: Application Setup** — Install and configure the tools your models need in production.
- **Lab 11: Instance Sizing** — Right-size your infrastructure to match your workload and budget.
- **Lab 12: Accessibility** — Build inclusive applications that work for everyone.

## How to use this book

You don't have to read straight through. Each lab is self-contained, but they're designed to build on each other. If you're new to deployment, start with Lab 1. If you've shipped APIs before but haven't used AWS, jump to Lab 7.

Every lab includes practical, working code. You'll build actual APIs, run them locally, deploy them to the cloud, and automate the whole process. The goal is not to teach theory—it's to equip you to do this work yourself.

## Getting started

The easiest way to follow along is to clone this repository and work through the labs on your machine:

```bash
git clone https://github.com/mjfrigaard/do4ds-labs.git
cd do4ds-labs
```

Each lab folder (`_labs/lab01/`, `_labs/lab02/`, etc.) contains the code and documentation for that lab. Follow the instructions in each `.qmd` file to set up your environment and run the examples.

## Reading the book online

The full book is published at [mjfrigaard.github.io/do4ds-labs/](https://mjfrigaard.github.io/do4ds-labs/). You can read it in your browser without setting anything up locally.

## Prerequisites

The labs assume you're comfortable with Python or R, and that you have a basic understanding of the command line. You don't have to love the command line, but it helps to be comfortable typing a few basic commands.

To run the code locally, you'll need:

- Python 3.12+ with pip
- R 4.4+
- Docker (for Lab 6 onward)
- An AWS account (for Lab 7 onward)
- Git

Each lab provides specific setup instructions as needed.

## Building the book locally

This book is built with [Quarto](https://quarto.org/). To render it locally:

```bash
quarto render
quarto preview
```

The rendered book will open in your browser at `http://localhost:3456/`.

## Contributing

Found an error or have feedback? Open an issue or pull request on [GitHub](https://github.com/mjfrigaard/do4ds-labs/issues). I'm interested in hearing where the labs are unclear or missing material.

## License

This book is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). You're free to use and adapt the material as long as you give attribution.

## More resources

- [DO4DS: DevOps for Data Science](https://do4ds.com/) — The companion book covering concepts and principles
- [Posit Connect documentation](https://docs.posit.co/connect/) — For deploying Shiny and API apps
- [AWS documentation](https://docs.aws.amazon.com/) — Comprehensive AWS guides

---

If you're building data science infrastructure or deploying models to production, I hope these labs save you time. Start with [Lab 1](https://mjfrigaard.github.io/do4ds-labs/lab01.html) or jump to whichever lab matches where you are in your journey.
