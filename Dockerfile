FROM ubuntu:17.04
RUN apt update -y
RUN apt upgrade -y
RUN apt install -y python3-pip python3-dev build-essential
COPY . /var/www/html/echo
WORKDIR /var/www/html/echo
RUN pip3 install -r requirements.txt
EXPOSE 5000
ENTRYPOINT ["python3"]
CMD ["wsgi.py"]
