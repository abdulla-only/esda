import { useEffect, useState } from "react";
import { Cell, List, Section, Spinner } from "@telegram-apps/telegram-ui";

import { catalogApi } from "../api/client";
import type { Deck } from "../api/types";

function DeckRows({
  decks,
  depth,
  onStudy,
}: {
  decks: Deck[];
  depth: number;
  onStudy: (deckId: number) => void;
}) {
  return (
    <>
      {decks.map((deck) => (
        <div key={deck.id}>
          <Cell
            style={{ paddingLeft: 16 + depth * 16 }}
            subtitle={`${deck.card_count} cards`}
            onClick={() => onStudy(deck.id)}
          >
            {deck.name}
          </Cell>
          {deck.children && deck.children.length > 0 && (
            <DeckRows decks={deck.children} depth={depth + 1} onStudy={onStudy} />
          )}
        </div>
      ))}
    </>
  );
}

export function Decks({ onStudy }: { onStudy: (deckId: number) => void }) {
  const [decks, setDecks] = useState<Deck[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    catalogApi
      .deckTree()
      .then(setDecks)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="page center">
        <Spinner size="l" />
      </div>
    );
  }

  return (
    <div className="page">
      <List>
        <Section header="Decks" footer="Tap a deck to study it.">
          <DeckRows decks={decks} depth={0} onStudy={onStudy} />
        </Section>
      </List>
    </div>
  );
}
