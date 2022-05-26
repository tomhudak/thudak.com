---
layout: post
title: "Building a .NET Core App Server to Send Firebase Cloud Messaging Message Requests"
permalink: /blog/2020-03-22-building-a-net-core-app-server-to-send-firebase-cloud-messaging-message-requests/
date: 2020-03-22 14:00:00 +0100
categories: dotnet core firebase push message
description: "With this guide you can set up a Firebase messaging connection using .NET"
comments: true
---

For a recent Android project of mine I introduced push messages for my app. I was using Xamarin for Android, and this guide was great help from Gulam Ali Hakim to understand how the Firebase Cloud Messaging (FCM) works and how to set it up in my application. I managed to send push messages to my test devices using the Firebase Console, but I also wanted to create a server app to send those message requests when certain conditions are met.

## How does Firebase Cloud Messaging work?

This is a messaging service that helps you send your push messages completely free (at least at the time of writing this article).

- You create a project in Firebase Console then set it up in your application.
- Whenever you install your application from a device, that device token is registered in a list for your Firebase project.
- You send Message Requests to Firebase and it is broadcasting to those registered devices where certain conditions are met (e.g. device is subscribed to a topic). You can send these Message Requests using Firebase Console **OR** by creating a service that does it for you…and that's how I did it.

There are bunch of guides for creating such service using the Firebase libraries in node.js or calling Firebase's API directly, but I wanted to create a .NET Core service that is using the `FirebaseAdmin` package supplied by Firebase itself.

In this tutorial, let's create a simple console app that sends a message to a Topic or a specific device.

## Create Firebase Service Account key

At this point you already should have access to Firebase Console and your project created there. In order to be able to connect to Firebase, you need to generate a private key, download it in a JSON format and include it in your Server Application project.

- Select your project in Firebase then navigate to 'Project settings'
[![Project settings](/assets/2020-03-22-firebase/2020-03-22-firebase-image-1.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-1.png)

- Select the 'Service accounts' tab then press 'Generate new private key' button.
[![Generate new private key](/assets/2020-03-22-firebase/2020-03-22-firebase-image-2.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-2.png)

- Save the generated JSON file.

## Create Server Application
**TLDR;** You can check out the full source in my GitHub repo: [tomhudak/FirebaseCloudMessaging.Example](https://github.com/tomhudak/FirebaseCloudMessaging.Example)

If you want some explanation for this code, stay with me and follow the guide.

**1.** Let's create a new Console App Project first. You can use [Visual Studio](https://docs.microsoft.com/en-us/visualstudio/get-started/csharp/tutorial-console?view=vs-2019) or .NET Core CLI to do this.

`dotnet new console --name FirebaseCloudMessaging.Example`

**2.** Now let's include the JSON key we have downloaded from Firebase. Copy it to the root folder of your project (in my example this is called `key.json`)

[![key.json](/assets/2020-03-22-firebase/2020-03-22-firebase-image-3.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-3.png)

To make sure that it is copied next to the compiled binary, set its 'Copy to Output Directory' property to 'Copy if newer' or 'Always copy' in the file properties.

[![Copy to Output Directory](/assets/2020-03-22-firebase/2020-03-22-firebase-image-4.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-4.png)

You can also achieve this by adding the following `<ItemGroup>` section to the `FirebaseCloudMessaging.Example.csproj` file

```csharp
    <ItemGroup>
        <None Update="key.json">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
```

**3.** Add FirebaseAdmin Nuget Reference

Right click on the solution and select 'Manage NuGet Packages for Solution…"

[![Manage NuGet packages for Solution...](/assets/2020-03-22-firebase/2020-03-22-firebase-image-5.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-5.png)

Search for 'FirebaseAdmin', select the project where you would like to include (in our case 'FirebaseCloudMessaging.Example') then press 'Install'
or you can just add the following `<ItemGroup>` section to `FirebaseCloudMessagingExample.csproj`

```csharp
    <ItemGroup>
        <PackageReference Include="FirebaseAdmin" Version="1.9.2" />
    </ItemGroup>
```

[![FirebaseAdmin](/assets/2020-03-22-firebase/2020-03-22-firebase-image-6.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-6.png)

**4.** Now let's add some code to our Program.cs to make it work.

Firstly, add the following `using`s, you will need them later.

```csharp
    using FirebaseAdmin;
    using FirebaseAdmin.Messaging;
    using Google.Apis.Auth.OAuth2;
    using System;
    using System.IO;
    using System.Threading.Tasks;
```

The below snippet shows how we are creating a new Firebase App. You can use the resulting `FirebaseApp` object to reach for properties such as the 'Name' of the app.

```csharp
    var defaultApp = FirebaseApp.Create(new AppOptions()
    {
        Credential = GoogleCredential.FromFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "key.json")),
    });
    Console.WriteLine(defaultApp.Name); // "[DEFAULT]"
```

FCM messages has two main types, `Notification` and `Data`. `Notification` messages are presented on the end-user devices on behalf of the client app, these are the typical push notification messages. `Data` messages contains custom key value pairs that is up for the client app how it is handling it (`Notification` messages can also contain a `Data` section). You can read more about this in the About [FCM Messages](https://firebase.google.com/docs/cloud-messaging/concept-options) documentation on Firebase.

Let's create a very simple notification `Message` object now.

```csharp
    var message = new Message()
    {
        Notification = new Notification
        {
            Title = "Message Title",
            Body = "Message Body"
        },
        Topic = "news"
    };
```

In the `Notificaton` property you describe the `Title` and the `Body` for your notification, but as I described you can also include a `Data` section and image to your notification message if you want.

You can specify the conditions for the audience of your message to be published, in the above case everyone gets a notification who is subscribed to the 'news' topic. You can also send a message to a specific device, or a list a devices using the `Token` property. For more info regarding the available options check out the [Build app server send requests](https://firebase.google.com/docs/cloud-messaging/send-message) documentation on Firebase and my full example in my [GitHub repo](https://github.com/tomhudak/FirebaseCloudMessaging.Example).

Now that our message request is ready, let's just send it.

```csharp
    var messaging = FirebaseMessaging.DefaultInstance;
    var result = await messaging.SendAsync(message);
    Console.WriteLine(result); //projects/myapp/messages/2492588335721724324
```

For a full example please check out my code here: [https://github.com/tomhudak/FirebaseCloudMessaging.Example](https://github.com/tomhudak/FirebaseCloudMessaging.Example)

[![Example message](/assets/2020-03-22-firebase/2020-03-22-firebase-image-7.png)](/assets/2020-03-22-firebase/2020-03-22-firebase-image-7.png)
<p class="italic center">An example message</p>

Hope this guide helps you get started on sending Message Requests. If so, please have a feedback by commenting, giving a clap, follow or share. Thanks!

This post is also published on [Medium](https://medium.com/@tamashudak/building-net-core-app-server-to-send-firebase-cloud-messaging-message-requests-641f3c6c90ae).
