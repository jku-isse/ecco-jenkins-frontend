FROM cypress/included:latest
 
COPY ./forDocker/ /home/frontend
RUN npm ci --prefix /home/frontend \
&& chmod -R 777 /root/.cache/Cypress \
&& chmod -R 777 /home/frontend
EXPOSE 8080
ENTRYPOINT []
CMD cd /home/frontend/ && npm run startReact
