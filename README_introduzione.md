 <h1 align="center">Track 3</h1>

## Struttura
```text
formazione_cm/
├── Jenkinsfile
├── README.md
├── Vagrantfile
├── inventory.ini
├── playbook.yml
├── requirements.yml
└── roles/
    ├── step1/
    │   ├── README.md
    │   └── tasks/
    │       ├── main.yml
    │       ├── podman.yml
    │       └── registry-podman.yml
    │
    ├── step2/
    │   ├── README.md
    │   ├── files/
    │   │   ├── rocky/
    │   │   │   └── Containerfile
    │   │   └── ubuntu/
    │   │       └── Containerfile
    │   └── tasks/
    │       ├── main.yml
    │       ├── containers.yml
    │       ├── firewall.yml
    │       └── podman.yml
    │
    ├── step3/
    │   ├── README.md
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── files/
    │   │   ├── rocky/
    │   │   │   └── Containerfile
    │   │   └── ubuntu/
    │   │       └── Containerfile
    │   └── tasks/
    │       ├── main.yml
    │       ├── containers-dp.yml
    │       ├── firewall.yml
    │       ├── registry-dp.yml
    │       └── runtime.yml
    │
    └── step5/
        ├── README.md
        ├── defaults/
        │   └── main.yml
        ├── files/
        │   ├── Dockerfile
        │   └── docker-entrypoint.sh
        ├── handlers/
        │   └── main.yml
        ├── tasks/
        │   ├── main.yml
        │   ├── container-docker.yml
        │   ├── docker.yml
        │   └── registry-docker.yml
        └── templates/
            └── daemon.json.j2
```

## Avvio della macchina virtuale
Per avviare la macchina virtuale definita nel `Vagrantfile`:
```bash
vagrant up
```

Per verificare lo stato della macchina:
```bash
vagrant status
```

Per verificare la connessione con Ansible:
```bash
ansible rocky -i inventory.ini -m ansible.builtin.ping
```
output atteso:
```text
rocky6 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Prerequisiti
Prima di eseguire il `playbook.yml`è necessario installare le collections presenti nel file `requirements.yml`: 
```bash
ansible-galaxy collection install -r requirements.yml
```

Per verificare l'installazione delle collections:
```
vagrant --version
VBoxManage --version
ansible --version
```

## Playbook
Il file `playbook.yml` rappresenta l'entry point principale di Ansible per il progetto.
È l'unico playbook da eseguire direttamente: al suo interno vengono definite la macchina gestita, le operazioni preliminari e i roles corrispondenti ai diversi step.

Prima dell'esecuzione dei roles viene eseguita una `pre_task` che genera una coppia di chiavi SSH, la chiave viene utilizzata per permettere all'utente `genericuser` di autenticarsi tramite SSH nei container creati durante gli esercizi:
```
pre_tasks:
  - name: Generate SSH key pair
    community.crypto.openssh_keypair:
      path: /home/vagrant/.ssh/id-genericuser
      type: ed25519
      state: present
```
La chiave privata viene mantenuta sulla macchina virtuale e utilizzata dal client SSH, mentre la chiave pubblica viene copiata nei container e inserita nel file `authorized_keys` dell'utente `genericuser`.

In questo modo è possibile accedere ai container tramite SSH **senza utilizzare una password**.
La coppia di chiavi è composta da:
```
/home/vagrant/.ssh/id-genericuser
/home/vagrant/.ssh/id-genericuser.pub
```

I `roles`vengono presentati in questo modo:
```bash
  roles:
    - { role: step1, tags: ["step1"] }
    - { role: step2, tags: ["step2"] }
    - { role: step3, tags: ["step3"] }
    - { role: step5, tags: ["step5"] }
```
Ogni esercizio è quindi implementato come un Ansible Role indipendente.
Ogni esercizio è documentato nel README presente all'interno del relativo role.

Per eseguire l'intero progetto:
```
ansible-playbook -i inventory.ini playbook.yml
```

Per eseguire solamente uno specifico role è invece possibile utilizzare i tag:
```bash
ansible-playbook -i inventory.ini playbook.yml --tags step*
```

## Esecuzione 
Quando viene eseguito `playbook.yml`, Ansible segue questo ordine:
1. Si connette all'host `rocky` definito nell'`inventory.ini`.
2. Esegue le `pre_tasks`.
3. Genera la coppia di chiavi SSH, se non è già presente.
4. Esegue i roles nell'ordine definito nel playbook:
    - `step1`
    - `step2`
    - `step3`
    - `step5`
5. All'interno di ogni role viene eseguito il relativo `tasks/main.yml`, che coordina gli altri task file.

## Pipeline Jenkins
La pipeline è composta da due stage principali:

`Build image`, esegue la build dell'immagine Docker utilizzando il `Dockerfile` dello Step 5 e assegna all'immagine un tag progressivo basato sulla variabile `${BUILD_NUMBER}` fornita da Jenkins.

`Push image`, pubblica l'immagine appena creata sul registry Docker utilizzando lo stesso tag della build.

L'immagine viene quindi identificata nel seguente modo:
```
192.168.56.112:5002/step5-docker:${BUILD_NUMBER}
```