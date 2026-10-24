---
title: "Phoenix LiveView after almost ten years of React: what I miss, what I don't"
date: 2026-10-21
excerpt: "A full-stack pivot in the middle of my career, told through the bugs it gave me."
tags: ["elixir", "react", "career"]
draft: false
---

When I joined Workera I had been writing React for almost ten years, and I moved to Elixir and Phoenix LiveView. This post is about that switch: why it happened, what changed in my head, the bugs that taught me the most, and what each side still does better.

Table of contents

1. Why the switch happened
2. The mental model shift
3. Bugs that taught me the most
4. What React still does better
5. What LiveView still does better
6. Would I do it again?

## Why the switch happened

Almost ten years of React: close to two at Treatwell, more than six at EclecticIQ, almost one at Intel 471. I was good at it, but I felt I was settling into a React mindset: thinking about every problem in terms of components, props and client state, and spending all my attention on the UI.

Workera's stack was Elixir and Phoenix LiveView. I didn't pick it (it was already there), and it was one of the most exciting parts of the new role: a language I had never used, a different way of building web apps, and a lot more backend than I was used to. I wanted to open my mind a bit and learn to think differently.

The first months were intense, and very exciting: new language, new product, and real-time over WebSockets, which I had never really worked with.

## The mental model shift

In React, the browser owns the state. You fetch data, keep it in a store, and the UI re-renders when the state changes. The server is something you call.

In LiveView it's the opposite. Each user has a long-lived process on the server, connected to the page over a WebSocket, and the state lives there, in the socket's assigns. Events from the browser (a click, a form change) travel up the socket, the server updates the state, re-renders the template and sends back only the diff. So there is no client store, no fetch layer and no API to design between frontend and backend: that's a lot of code you simply don't write.

The questions change too. In React I asked where to keep this state in the client. In LiveView I ask how much of it I want to keep in memory, on the server, for every connected user.

## Bugs that taught me the most

### The session that couldn't find its way back

At some point we had a bug where the UI and the backend would lose each other. Problem: the ID that tied a LiveView session to its page wasn't deterministic, so when the connection dropped and the client tried to reconnect, the backend couldn't match it back to the right session. The result was a page that looked alive but behaved strangely.

The worst part was that it happened at random: no reliable repro, no obvious error. We spent a lot of time debugging without getting anywhere, because the real problem was reproducing it. When we finally managed to, it was partly trial and error, following one clue to the next. From there the fix came by exclusion: we removed everything we could prove was fine, until only a few suspects were left, and the session ID was one of them.

What I took from it: in LiveView the connection is part of your application state. In other words: a reconnect is a code path like any other, and it needs the same care.

### A disabled button is just an attribute

This one surprised me more than it should have. In LiveView, a disabled button is exactly that: a `<button disabled>` in the HTML. Open the dev tools, remove the attribute, click, and the event goes to the server like any other (!).

We had a form where the save button was disabled for users who weren't allowed to save. Remove the attribute and the save went through, because the server never checked.

This was our mistake more than LiveView's: the authorization check belonged in the `handle_event` on the server, and it wasn't there. But I think LiveView makes this mistake easy to make, because it feels like you are writing server code all the time. You are, but the events still come from a browser, and the browser is under the user's control. They don't even need the button: anyone with a browser console can push the event over the socket directly. So the rule is the same as for any API: every event that changes data needs a server-side permission check, whatever the UI shows.

### React inside LiveView, and the state that lived twice

Some parts of our UI were React components, mounted inside a LiveView page through a JavaScript hook. The flow looked roughly like this:

```js
// app.js
let Hooks = {}

Hooks.ReactWidget = {
  mounted() {
    // Create the React root once, when the element first appears.
    // Re-creating it on every LiveView update would reset all React state.
    this.root = createRoot(this.el)
    this.render()

    // React → server: send user actions over the LiveView socket
    this.pushToServer = (event, payload) => this.pushEvent(event, payload)
  },

  updated() {
    // LiveView re-rendered this element: read the new server data
    // and hand it to React, which decides what to re-render.
    this.render()
  },

  destroyed() {
    this.root.unmount()
  },

  render() {
    const props = JSON.parse(this.el.dataset.props)
    this.root.render(<Widget {...props} onAction={this.pushToServer} />)
  },
}

let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })
```

```heex
<div id="widget" phx-hook="ReactWidget" phx-update="ignore" data-props={Jason.encode!(@widget_props)}></div>
```

Two details matter here:

1. `phx-update="ignore"` tells LiveView not to patch the DOM inside that element, because React owns it now.
2. The React root is created once, in `mounted`, and not on every update.

It worked, but the cost was the state. Part of it lived in the LiveView assigns on the server, part of it in React state on the client, and keeping the two in sync was our job. Every bug in that area was a version of the same question: which side is right?

## What React still does better

It's a UI framework, and it shows: managing UI state and events comes out of the box. Little example: LiveView has bindings for clicks, keys, focus and blur, but there's no double-click binding, so you write a JS hook for it. In React it's `onDoubleClick`.

The ecosystem is bigger. Date pickers, rich text editors, drag and drop, charts, data grids: React has mature libraries for all of them, and LiveView mostly doesn't. In practice this is why so many LiveView apps end up embedding React or another JS library for the complex widgets... and then you're back to the integration problem above.

In React I think state management is a solved problem: after years of Redux, Context and Zustand, keeping state on the client is easy. In LiveView the state lives on the socket, in server memory, for every connected user, so you have to keep it as light as possible and only store what you need. Passing data down to nested components also felt clunkier to me than props in React.

## What LiveView still does better

There is no API layer between frontend and backend: no REST endpoints or GraphQL schemas to design, no client-side fetching, no loading-state plumbing for every request. For a lot of features, a LiveView is a template and a few event handlers, and that's it!

Real-time comes for free. The page is already connected over a socket, so pushing an update from the server to every user looking at a page takes a few lines of PubSub.

Logic and data live together, on the server, in Elixir. That was exactly what I came for: I spent a lot more time thinking about the backend, and I think it made me a more complete engineer.

## Would I do it again?

Yes. I went looking for a new way of thinking, and LiveView gave me one: state on the server, the connection as part of the app, every client event as untrusted input. I bring those back to React projects now.

Would I pick LiveView for every project? No. For apps that are mostly forms, dashboards and real-time updates, I think it's hard to beat. For highly interactive UIs that lean on the JS ecosystem, I'd still reach for React, and I'd think hard before mixing the two.

Thanks for reading!
