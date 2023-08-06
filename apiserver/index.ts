import express from "express";

express()
  .get("/health", (req, res) => res.status(200).send("success"))
  .get("/", (req, res) => res.status(200).send("hello world"))
  .get("/a", (req, res) => res.status(200).send("a"))
  .get("/c", (req, res) => res.status(200).send("c"))
  .listen(process.env.PORT, () => {
    console.log(`${process.env.PORT} is connect`);
  });
