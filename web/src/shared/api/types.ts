export interface User {
  id: number;
  email: string;
  telegram_id: number | null;
  first_name: string;
  last_name: string;
}

export interface TokenPair {
  access: string;
  refresh: string;
}

export interface TelegramAuthResponse extends TokenPair {
  user: User;
}

export interface Deck {
  id: number;
  language: number;
  parent?: number | null;
  name: string;
  slug: string;
  order: number;
  card_count: number;
  children?: Deck[];
}

export type PartOfSpeech =
  | "noun"
  | "verb"
  | "adjective"
  | "adverb"
  | "phrase"
  | "other";

export interface ReviewState {
  is_new: boolean;
  state: number;
  due: string | null;
  reps?: number;
  lapses?: number;
}

export interface StudyCard {
  id: number;
  deck: number;
  front: string;
  back: string;
  description: string;
  example: string;
  part_of_speech: PartOfSpeech;
  review: ReviewState;
}

export interface StudyQueue {
  count: number;
  due_count: number;
  new_count: number;
  results: StudyCard[];
}

export type Rating = 1 | 2 | 3 | 4; // Again / Hard / Good / Easy
