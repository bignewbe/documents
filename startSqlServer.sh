docker run --restart always -d -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Password!' -v ~/mysql:/var/opt/mssql -p 1306:1433 --name sqlserver -h sqlserver mcr.microsoft.com/mssql/server:2022-latest
