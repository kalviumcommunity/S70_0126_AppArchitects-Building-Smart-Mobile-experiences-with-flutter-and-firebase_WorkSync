import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final TextDirection? textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Retrieve the translated text. It might be a Future if we load dynamically
        // but LanguageProvider handles the async part internally and returns the value
        // if cached, otherwise starts translating. To keep it simple, translate()
        // will return the original text if it's currently translating, and trigger
        // a rebuild when done.
        final translatedString = languageProvider.translate(text);
        
        return Text(
          translatedString,
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: softWrap,
          textDirection: textDirection,
          locale: locale,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        );
      },
    );
  }
}
