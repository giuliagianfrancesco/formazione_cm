# formazione_cm

Progetto Ansible per la creazione e gestione di un Docker registry locale, la build di container con diversi sistemi operativi con accesso remoto tramite chiave SSH, il push verso il registry e l'esecuzione dei container — con compatibilità Docker/Podman e credenziali protette tramite Ansible Vault.

---

## Step 1 - Registry

**Goal:** creare un Docker registry locale, senza autenticazione, riutilizzabile sia con Docker che con Podman.

**Moduli usati:**
- `community.docker.docker_container`
- `containers.podman.podman_container`
- `ansible.builtin.command` (per controllo uso Podman o Docker)
- `ansible.builtin.set_fact`

**Parametri chiave:**
- `name`: nome del container registry (`mio_registro`)
- `image`: `registry:2`
- `restart_policy`: `always`
- `ports`: mapping esplicito **host:container** (`"5000:5000"`) 

**Keyword:**
- `when: docker_installed` / `when: podman_installed and not docker_installed`: esegue il task solo se il motore corrispondente è attivo
- Controllo se attivo tramite `which docker` / `which podman`, salvato con `register`, con tolleranza all'errore tramite `ignore_errors: true`, e trasformato in una variabile booleana con `set_fact` in base al campo `.rc` (return code) del comando

---

## Step 2 - Build dei container

**Goal:** build di almeno due immagini con OS differenti (Rocky Linux 9, Ubuntu), con SSH attivo, in ascolto sulla porta 22, e un utente con permessi per accedere tramite chiave SSH.

**Moduli usati:**
- `community.crypto.openssh_keypair` (generazione coppia di chiavi)
- `ansible.builtin.template` (per la sostituzione Jinja2)
- `community.docker.docker_image` / `containers.podman.podman_image`

**Parametri chiave dei Dockerfile:**
- `useradd -m genericuser`: crea l'utente dedicato
- `chpasswd`: imposta la password (con Ansible vault viene messa non in chiaro)
- `authorized_keys`: chiave pubblica generata da Ansible
- `sshd_config`: `PermitRootLogin no`, `PasswordAuthentication no`, `PubkeyAuthentication yes`, `AllowUsers genericuser`: configurazione accesso SSH
- `EXPOSE 22`: porta esposta
- `CMD ["/usr/sbin/sshd","-D"]`: eseguibile di default

**Keyword:**
- I Dockerfile sono in `build_images/templates/`  perché uso il modulo `template` 
- `source: build`: dice al modulo di eseguire una build reale a partire da un Dockerfile

---

## Step 3 - Ruoli parametrizzati e compatibilità Docker/Podman

**Goal:** trasformare gli step precedenti in ruoli (miei ruoli: `registry`, `build_images`, `push_builds`, `run_containers`).

**Moduli usati:**
- `ansible.builtin.include_role` (con `loop` per iterare su più sistemi operativi)
- `community.docker.docker_network` / `containers.podman.podman_network`

**Parametrizzazione applicata:**
- `run_containers/defaults/main.yml`: definisce una porta SSH host e un IP, evitando conflitti tra i diversi container:
  ```yaml
  container_defaults:
    rocky:
      ssh_host_port: 2201
      ip: 172.20.0.7
    ubuntu:
      ssh_host_port: 2202
      ip: 172.20.0.6
  ```

**Keyword:**
- `loop` + `loop_control.loop_var`: necessario per iterare i ruoli su più sistemi operativi (`rocky`, `ubuntu`).
- `run_once: true`: per creazione della rete Docker/Podman, per evitare che venga ricreata ogni volta
- **Push image**: Serve un passaggio di **retag**  prima della push, perché la build produce l'immagine con un nome ma senza il riferimento al registry

---

## Step 4 - Ansible Vault

**Goal:** nascondere le password (utente nei Dockerfile) tramite Ansible Vault.

**Comandi usati:**
- `ansible-vault encrypt <file>`: cifra un file YAML 
- `ansible-vault view <file>`: visualizza il contenuto decifrato 
- `ansible-vault edit <file>`: modifica file visualizzandolo in chiaro

**Configurazione:**
- `/etc/ansible/ansible.cfg`:
  ```ini
  [defaults]
  vault_password_file = /etc/ansible/mysecret
  ```
- `/etc/ansible/vault_pass.yml` (cifrato): con la variabile `password_gen_user` per template Dockerfile

**Integrazione nel playbook test-role.yml:**
```yaml
vars_files:
  - /etc/ansible/vault_pass.yml
```


**Keyword:**
- Con `ansible.cfg` configurato, il flag --ask-vault-pass non serve per eseguire playbook test-role.yml
