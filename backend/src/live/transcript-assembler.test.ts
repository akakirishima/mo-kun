import assert from "node:assert/strict";
import { TranscriptAssembler } from "./transcript-assembler.js";

const assembler = new TranscriptAssembler();

const initialTurnId = assembler.currentResolvedTexts().turnId;

assembler.nextInput({
  text: "最初の発話",
  finished: false,
});
assembler.nextInput({
  text: "です",
  finished: false,
});
assembler.nextOutput({
  text: "途中までの返答",
  finished: false,
});
assembler.nextOutput({
  text: "です",
  finished: false,
});

assert.deepEqual(assembler.currentResolvedTexts(), {
  turnId: initialTurnId,
  inputText: "最初の発話です",
  outputText: "途中までの返答です",
});

assert.deepEqual(assembler.currentFinalTexts(), {
  turnId: initialTurnId,
  inputText: "",
  outputText: "",
});

assembler.nextInput({
  text: "最初の発話です",
  finished: true,
});
assembler.nextOutput({
  text: "最後までの返答です",
  finished: true,
});

assert.deepEqual(assembler.currentResolvedTexts(), {
  turnId: initialTurnId,
  inputText: "最初の発話です",
  outputText: "最後までの返答です",
});

assembler.beginNextTurn();

const nextTurn = assembler.currentResolvedTexts();
assert.notEqual(nextTurn.turnId, initialTurnId);
assert.equal(nextTurn.inputText, "");
assert.equal(nextTurn.outputText, "");

console.log("transcript-assembler tests passed");
