FROM cypress/included:latest
 
COPY ./forDocker/ /home/frontend
RUN npm install --prefix /home/frontend \
&& printf "npm run startReact" > /home/frontend/entrypoint.sh \
&& chmod -R 777 /root/.cache/Cypress \
&& chmod -R 777 /home/frontend
EXPOSE 8080
ENTRYPOINT []
CMD cd /home/frontend/ && npm run startReact
