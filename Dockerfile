FROM ubuntu
RUN apt-get update
RUN apt-get install apache2 -y
RUN apt-get install apache2-utils -y
RUN apt-get clean
EXPOSE 80
# RUN echo "<h1> Omm Namah Shivaya ! </h1>" > /var/www/html/index.html
COPY ./index.html /var/www/html/index.html
CMD ["apache2ctl","-D","FOREGROUND"]