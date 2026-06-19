# Lab 6

This lab covers putting the APIs in Docker containers. Instructions for running the container are provided in the respective API README files (`R/api/README.md` and `Python/api/README.md`).

## Installing Docker (Pop!_OS 24.04)

Download the Docker Desktop `.deb` from [docs.docker.com/get-docker](https://docs.docker.com/get-docker/).

Docker Desktop depends on `docker-ce-cli`, which is not in the default Pop!_OS repos. Add Docker's official APT repository before installing the `.deb`.

1. Install prerequisites:

```bash
sudo apt install ca-certificates curl gnupg lsb-release
```

2. Add Docker's GPG key:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

```bash
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

3. Add the Docker APT repository (use `ubuntu noble` for Pop!_OS 24.04):

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```bash
sudo apt update
```

4. Install Docker Desktop:

```bash
sudo apt install ./Downloads/docker-desktop-amd64.deb
```

The install may print a permission warning about `_apt` — this is harmless and the install completes normally.

5. Verify the install and start Docker Desktop:

```bash
docker --version
```

```bash
systemctl --user start docker-desktop
```

## Login 

See the [Docker Desktop login instructions](https://docs.docker.com/desktop/setup/sign-in/#credentials-management-for-linux-users).