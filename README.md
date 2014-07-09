# Hubot Quote File

Maintain a quote file of hilarious, out-of-context quotes from your chat, to bring then up later
either randomly or matching a search term.

## Installing

1. `npm install --save hubot-quotefile`
2. Require the module in `external-scripts.json`:

  ```json
  ["hubot-quotefile"]
  ```

3. Restart your Hubot.

## Commands

Memorable quotes are stored in a flat text file that you can also maintain with `${EDITOR}`. Its format is simple - separate each quote with two newlines:

```
quote one
still quote one, second line

quote two

a third quote
that's
three lines long
```

`Hubot: quote` will summon a random quote from the file.

`Hubot: quote Fenris corpse` will summon a random quote containing the words "Fenris" and "corpse".

`Hubot: reload quotes` will trigger an automatic, asynchronous reload of the file.

## Configuring

`HUBOT_QUOTEFILE_PATH` controls the location of the quotefile.
