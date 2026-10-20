// Purpose: Loads Testing Library DOM assertions and supplies TextEncoder/TextDecoder for the jsdom test environment.
import '@testing-library/jest-dom';
import { TextEncoder, TextDecoder } from 'util';
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;
