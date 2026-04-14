import CraftingEn from './en/crafting';
import EnchantEn from './en/enchant';
import GuildsEn from './en/guilds';
import ItemEn from './en/item';
import MiscEn from './en/misc';
import ResourceEn from './en/resource';
import StoreEn from './en/store';
import GameEn from './en/game';
import WarpsEn from './en/warps';
import CraftingZh from './zh/crafting';
import EnchantZh from './zh/enchant';
import GuildsZh from './zh/guilds';
import ItemZh from './zh/item';
import MiscZh from './zh/misc';
import ResourceZh from './zh/resource';
import StoreZh from './zh/store';
import GameZh from './zh/game';
import WarpsZh from './zh/warps';

export let resources = {
    en: {
        crafting: CraftingEn,
        enchant: EnchantEn,
        guilds: GuildsEn,
        item: ItemEn,
        misc: MiscEn,
        resource: ResourceEn,
        store: StoreEn,
        game: GameEn,
        warps: WarpsEn
    },
    zh: {
        crafting: CraftingZh,
        enchant: EnchantZh,
        guilds: GuildsZh,
        item: ItemZh,
        misc: MiscZh,
        resource: ResourceZh,
        store: StoreZh,
        game: GameZh,
        warps: WarpsZh
    }
} as const;

export type Locale = keyof typeof resources;

export let locales: { [K in Locale]: string } = {
    en: 'en-US',
    zh: 'zh-CN'
} as const;

export let defaultLocale = 'en' as const;
export let defaultResource = resources[defaultLocale];

export let ns = Object.keys(defaultResource);
export type Namespaces = typeof defaultResource;

declare module 'i18next' {
    interface CustomTypeOptions {
        returnNull: false;
        returnObjects: false;
        resources: typeof defaultResource;
    }
}
