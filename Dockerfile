FROM ubuntu
RUN apt-get update
RUN apt-get install apache2 -y
RUN apt-get install apache2-utils -y
RUN apt-get clean
EXPOSE 80
RUN echo "King of the Jungle" > /var/www/html/index.html
CMD ["apache2ctl","-D","FOREGROUND"]
