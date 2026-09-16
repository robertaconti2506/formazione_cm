 <h1 align="center">Step 1</h1>
Lo scopo di questo esercizio è configurare un ambiente con Podman e predisporre un container Registry privato locale.

`podman.yml`
Il task verifica se Podman che Podman sia installato sulla VM.
Se Podman non è presente, viene installato tramite `dnf` (essendo una VM Rocky).

Successivamente viene creato il volume Podman:
```
registry_data
```

`registry-podman.yml`
Viene scaricata l'immagine:
```
docker.io/library/registry:2
```
e viene avviato un container denominato:
```
registry
```