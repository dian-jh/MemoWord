var builder = DistributedApplication.CreateBuilder(args);

var wordDb = builder.AddConnectionString("memoword");

builder.AddProject<Projects.WordService_WebAPI>("wordservice-webapi")
    .WithReference(wordDb);

builder.Build().Run();
