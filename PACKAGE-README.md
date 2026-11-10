# ismkdc.MongoDB.EntityFrameworkCore

**Unofficial** build of the MongoDB EF Core provider with **EF Core 11 / .NET 11** support.
Not affiliated with, endorsed by, or supported by MongoDB, Inc.

Use the official
[`MongoDB.EntityFrameworkCore`](https://www.nuget.org/packages/MongoDB.EntityFrameworkCore)
package unless you specifically need EF Core 11 support.

## Install

```bash
dotnet add package ismkdc.MongoDB.EntityFrameworkCore --version 11.0.0
```

Targets `net11.0`; depends on `Microsoft.EntityFrameworkCore` 11.0.0 and `MongoDB.Driver` 3.13.0.

## Usage

```csharp
using Microsoft.EntityFrameworkCore;
using MongoDB.EntityFrameworkCore.Extensions;

var options = new DbContextOptionsBuilder<MyContext>()
    .UseMongoDB("mongodb://localhost:27017", "mydb")
    .Options;

public class MyContext(DbContextOptions<MyContext> options) : DbContext(options)
{
    public DbSet<Book> Books => Set<Book>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
        => modelBuilder.Entity<Book>().ToCollection("books");
}
```

## Support

- This unofficial build: https://github.com/ismkdc/mongo-efcore-provider/issues
- The MongoDB provider itself: https://github.com/mongodb/mongo-efcore-provider
