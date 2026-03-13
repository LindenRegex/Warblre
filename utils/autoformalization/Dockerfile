FROM rocq/rocq-prover:9.1

ENV DEBIAN_FRONTEND=noninteractive
RUN sudo apt-get update
RUN sudo apt-get install -y python3 python3-pip python3-venv

RUN whoami
RUN mkdir -p /home/rocq/workdir/
WORKDIR /home/rocq/workdir/

RUN git clone https://github.com/LindenRegex/Warblre.git warblre
RUN cd warblre; OPAMYES=1 opam pin add dune 3.21.1
RUN cd warblre; OPAMYES=1 opam install --deps-only .
RUN cd warblre; dune build
