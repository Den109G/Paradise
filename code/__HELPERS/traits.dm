// trait accessor defines
#define SIGNAL_ADDTRAIT(trait_ref) "addtrait [trait_ref]"
#define SIGNAL_REMOVETRAIT(trait_ref) "removetrait [trait_ref]"

#define ADD_TRAIT(target, trait, source) \
	do { \
		LAZYINITLIST(target.status_traits); \
\
		if(!target.status_traits[trait]) { \
			target.status_traits[trait] = list(source); \
		} else { \
			target.status_traits[trait] |= list(source); \
		} \
\
		SEND_SIGNAL(target, SIGNAL_ADDTRAIT(trait), trait); \
	} while (0)

#define REMOVE_TRAIT(target, trait, sources) \
	do { \
		if(target.status_traits && target.status_traits[trait]) { \
			var/list/SOURCES = sources; \
			if(sources && !islist(sources)) { \
				SOURCES = list(sources); \
			} \
\
			for(var/TRAIT_SOURCE in target.status_traits[trait]) { \
				if((!SOURCES && (TRAIT_SOURCE != ROUNDSTART_TRAIT)) || (TRAIT_SOURCE in SOURCES)) { \
					if(length(target.status_traits[trait]) == 1) { \
						SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(trait), trait); \
					} \
					LAZYREMOVEASSOC(target.status_traits, trait, TRAIT_SOURCE); \
				} \
			} \
		} \
	} while (0)

#define REMOVE_TRAITS_NOT_IN(target, sources) \
	do { \
		var/list/_L = target.status_traits; \
		var/list/_S = sources; \
		if (_L) { \
			for (var/_T in _L) { \
				_L[_T] &= _S;\
				if (!length(_L[_T])) { \
					_L -= _T } \
				};\
				if (!length(_L)) { \
					target.status_traits = null\
				};\
		}\
	} while (0)

#define REMOVE_TRAITS_IN(target, sources) \
	do { \
		if(target.status_traits) { \
			var/list/SOURCES = sources; \
			if(!islist(sources)) { \
				SOURCES = list(sources); \
			} \
\
			for(var/TRAIT in target.status_traits) { \
				if(!target.status_traits[TRAIT]) \
					continue; \
				target.status_traits[TRAIT] -= SOURCES; \
				if(!length(target.status_traits[TRAIT])) { \
					target.status_traits -= TRAIT; \
					SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(TRAIT)); \
					if(!target.status_traits) \
						break; \
				} \
			} \
			if(!length(target.status_traits)) { \
				target.status_traits = null; \
			} \
		} \
	} while (0)
#define HAS_TRAIT(target, trait) (target.status_traits ? (target.status_traits[trait] ? TRUE : FALSE) : FALSE)
#define HAS_TRAIT_FROM(target, trait, source) (target.status_traits ? (target.status_traits[trait] ? (source in target.status_traits[trait]) : FALSE) : FALSE)

/*
Remember to update _globalvars/traits.dm if you're adding/removing/renaming traits.
*/

//mob traits
#define TRAIT_PACIFISM			"pacifism"
#define TRAIT_WATERBREATH		"waterbreathing"
#define TRAIT_BLOODCRAWL		"bloodcrawl"
#define TRAIT_BLOODCRAWL_EAT	"bloodcrawl_eat"
#define TRAIT_JESTER			"jester"
#define TRAIT_FORCE_DOORS "force_doors"
#define VAMPIRE_TRAIT "vampire"

//
// common trait sources
#define ROUNDSTART_TRAIT "roundstart" //cannot be removed without admin intervention
#define CULT_TRAIT "cult"
#define CLOCK_TRAIT "clockwork cult"

// unique trait sources
#define CULT_EYES "cult_eyes"
#define CLOCK_HANDS "clock_hands"
