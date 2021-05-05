<#
    Entity-Framework-QuickScript
    Copyright (C) 2021 Filip Strajnar
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

# dotnet ef dbcontext scaffold "connection-string" MySql.EntityFrameworkCore -o sakila -f

function BuildSQLite {
    param (
        [string] $nmspace,
        [string] $dbname,
        [string] $contextnm
    )
    $template_string_sqlite = "using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ${nmspace}
{
    public class ${contextnm}Context : DbContext
    {
        public DbSet<SomeClass> someclass { get; set; }

        // The following configures EF to create a Sqlite database file as `C:\blogging.db`.
        // For Mac or Linux, change this to `/tmp/blogging.db` or any other absolute path.
        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseSqlite(@`"Data Source=${dbname}.db`");
    }

    public class SomeClass
    {
        public int Id { get; set; }
        public int something { get; set; }
        public string something1 { get; set; }
    }
}"
    $template_string_sqlite | Out-File DB_autogen.cs
    return $template_string_sqlite
}
#TODO: CHANGE NAMESPACE, CHANGE CONNECTION STRING, CHANGE CONTEXTNAME

function BuildMySQL {
    param (
        [string] $connection_string_mysql,
        [string] $namespace,
        [string] $contextName
    )

    $template_string_MySQL = "using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace MySQL_db
{
    public class BloggingContext : DbContext
    {
        public DbSet<SomeClass> someclass { get; set; }

        // The following configures EF to create a Sqlite database file as `C:\blogging.db`.
        // For Mac or Linux, change this to `/tmp/blogging.db` or any other absolute path.
        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseMySQL(`"Server=localhost;Database=testing;Uid=root;Pwd=U6KT9+6WVKDrufRAjCPjFR2otKe+;`");
    }

    public class SomeClass
    {
        public int Id { get; set; }
        public int something { get; set; }
        public string something1 { get; set; }
    }
}"

}
function CodeFirst {
    Write-Host "Name the file for DbContext (without.cs)"
    $file_name = Read-Host

}

function DBFirst {
    param (
        [string] $connection_string
    )
    dotnet ef dbcontext scaffold "${connection_string}" MySql.EntityFrameworkCore -o sakila -f
}

function InstallDependencies {
    dotnet add package Microsoft.EntityFrameworkCore.Sqlite
    dotnet add package MySql.EntityFrameworkCore
    dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
    dotnet add package MySql.Data.EntityFrameworkCore
    dotnet tool install --global dotnet-ef
    dotnet tool update --global dotnet-ef
    dotnet add package Microsoft.EntityFrameworkCore.Design
    dotnet add Microsoft.EntityFrameworkCore.Tools
}

function CodeFirst_orDBfirst {
    param (
        [string] $sqliteORmysql
    )
    $usingCodeOrDBfirst=Read-Host "Type 1 if you wish to use Code First, type 2 if you wish to use Database First"
    if($usingCodeOrDBfirst -eq "1") #This means Code first
    {
        if($sqliteORmysql -eq "1"){ #SQLite
            $namescapecontroller=Read-Host "Please insert name of your namespace"
            $sqlitename=Read-Host "Please insert name of your Sqlite DB"
            $namecontext=Read-Host "Please insert name of your context (without Context at the end)"
            BuildSQLite $namescapecontroller $sqlitename $namecontext 
            
            Write-Host "Change the DB context to your needs and execute the following:"
            Write-Host "dotnet ef migrations add <somename>"
            Write-Host "dotnet ef database update"
            return
        }
        if($sqliteORmysql -eq "2"){ #MySQL
            $connection_string_get=Read-Host "Please insert valid connection string for MySQL"
            dotnet ef dbcontext scaffold $connection_string MySql.EntityFrameworkCore -o Autogen -f
            return
        }
        return
    }
    if($usingCodeOrDBfirst -eq "2") #This means Database first
    {
        if($sqliteORmysql -eq "1"){ #SQLite
            Write-Host "Not implemented."
            return
        }
        if($sqliteORmysql -eq "2"){ #MySQL
            $connection_string_get=Read-Host "Please insert valid connection string for MySQL"
            dotnet ef dbcontext scaffold $connection_string_get MySql.EntityFrameworkCore -o Autogen -f
            return
        }

        
    }
    Write-Host "Invalid input, try again"
    CodeFirst_orDBfirst
}

function GetDb {
    $using_db=Read-Host "Type 1 if you're using SQLite, type 2 if you're using MySQL"

    if ($using_db -eq  "1"){
        Write-Host "You are using SQLite"
        CodeFirst_orDBfirst $using_db
        return
    }
    if ($using_db -eq "2") {
        Write-Host "You are using MySQL"
        CodeFirst_orDBfirst $using_db
        return
    }
    Write-Host "Invalid input, try again"
    GetDb
}

function NeedDepend {
    $needdep=Read-Host "Do you need to install dependencies for Entity Framework? Type `"yes`" if you do"
    if($needdep -eq "yes"){
        InstallDependencies
    }
}

NeedDepend
GetDb