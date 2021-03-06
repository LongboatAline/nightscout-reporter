import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:nightscout_reporter/src/globals.dart';
import 'package:nightscout_reporter/src/jsonData.dart';

import 'base-print.dart';


class CollectInfo
{
  DateTime start;
  DateTime end;
  double sum;
  double max = -1.0;
  int count = 0;

  CollectInfo(this.start, [double this.sum = 0.0])
  {
    end = DateTime(start.year, start.month, start.day, start.hour, start.minute, start.second);
    count = sum > 0.0 ? 1 : 0;
    max = sum;
  }

  void fill(DateTime date, double value)
  {
    end = DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second);
    sum += value;
    max = math.max(value, max);
    count++;
  }
}

class PrintDailyGraphic extends BasePrint
{
  @override
  String id = "daygraph";

  bool showPictures, showInsulin, showCarbs, showBasalDay, showBasalProfile, showLegend, isPrecise, isSmall, showNotes,
    sortReverse, showGlucTable, showSMBAtGluc, showInfoLinesAtGluc, sumNarrowValues, showSMB;

  @override
  List<ParamInfo> params = [
    ParamInfo(0, msgParam1, boolValue: true),
    ParamInfo(1, msgParam2, boolValue: true),
    ParamInfo(4, msgParam3, boolValue: true),
    ParamInfo(5, msgParam4, boolValue: true),
    ParamInfo(6, msgParam5, boolValue: true),
    ParamInfo(7, msgParam6, boolValue: false),
    ParamInfo(11, msgParam7, boolValue: false),
    ParamInfo(9, msgParam8, boolValue: true),
    ParamInfo(8, msgParam9, boolValue: true),
    ParamInfo(10, msgParam10, boolValue: false),
    ParamInfo(12, msgParam11, boolValue: true),
    ParamInfo(3, msgParam12, boolValue: true),
    ParamInfo(13, msgParam13, boolValue: false),
    ParamInfo(14, msgParam14, boolValue: true),
    ParamInfo(2, msgParam15, boolValue: true),
  ];


  @override
  prepareData_(ReportData data)
  {
    showPictures = params[0].boolValue;
    showInsulin = params[1].boolValue;
    showCarbs = params[2].boolValue;
    showBasalDay = params[3].boolValue;
    showBasalProfile = params[4].boolValue;
    isPrecise = params[5].boolValue;
    isSmall = params[6].boolValue;
    showLegend = params[7].boolValue;
    showNotes = params[8].boolValue;
    sortReverse = params[9].boolValue;
    showGlucTable = params[10].boolValue;
    showSMBAtGluc = params[11].boolValue;
    showInfoLinesAtGluc = params[12].boolValue;
    pagesPerSheet = isSmall ? 4 : 1;
    sumNarrowValues = params[13].boolValue;
    showSMB = params[14].boolValue;

    return data;
  }

  static String _titleGraphic = Intl.message("Tagesgrafik");
  static String _titleNotes = Intl.message("Tagesnotizen");

  @override
  String title = _titleGraphic;

  static String get msgParam1
  => Intl.message("Symbole (Katheter etc.)");
  static String get msgParam2
  => Intl.message("Insulin");
  static String get msgParam3
  => Intl.message("Kohlenhydrate");
  static String get msgParam4
  => Intl.message("Tages-Basalrate");
  static String get msgParam5
  => Intl.message("Profil-Basalrate");
  static String get msgParam6
  => Intl.message("Basal mit zwei Nachkommastellen");
  static String get msgParam7
  => Intl.message("Vier Grafiken pro Seite");
  static String get msgParam8
  => Intl.message("Legende");
  static String get msgParam9
  => Intl.message("Notizen");
  static String get msgParam10
  => Intl.message("Neuester Tag zuerst");
  static String get msgParam11
  => Intl.message("Tabelle mit Glukosewerten");
  static String get msgParam12
  => Intl.message("SMB an der Kurve platzieren");
  static String get msgParam13
  => Intl.message("Info-Linien bis zur Kurve zeichnen");
  static String get msgParam14
  => Intl.message("Nahe zusammen liegende Werte aufsummieren");
  static String get msgParam15
  => Intl.message("SMB Werte anzeigen");

  @override
  List<String> get imgList
  => ["nightscout", "katheter.print", "sensor.print", "ampulle.print"];

//  @override
//  double get scale
//  => isSmall ?? false ? (g.isLocal ? 0.25 : 0.5) : 1.0;

  @override
  bool get isPortrait
  => false;

  num lineWidth;
  double glucMax = 0.0;
  double profMax = 0.0;
  double carbMax = 200.0;
  double bolusMax = 50.0;
  double ieMax = 0.0;
  double graphHeight;
  double graphBottom;
  static double graphWidth;
  static double notesTop = 0.4;
  static double notesHeight = 0.3;
  static double basalTop;
  static double basalHeight = 3.0;
  static double basalWidth = graphWidth;
  double glucTableHeight = 0.6;

  double glucX(DateTime time)
  {
    return graphWidth / 1440 * (time.hour * 60 + time.minute);
  }

  double glucY(double value)
  => graphHeight / glucMax * (glucMax - value);

  double carbY(double value)
  => graphHeight / carbMax * (carbMax - value);

  double bolusY(double value)
  => graphHeight / 4 * value / ieMax;

  double smbY(double value)
  => graphHeight / 50 * value;

  double basalX(DateTime time)
  {
    return basalWidth / 1440 * (time.hour * 60 + time.minute);
  }

  double basalY(double value)
  => profMax != 0 && value != null ? basalHeight / profMax * (profMax - value) : 0.0;

  List<CollectInfo> collInsulin = List<CollectInfo>();
  List<CollectInfo> collCarbs = List<CollectInfo>();

  PrintDailyGraphic()
  {
    init();
  }

  @override
  void fillPages(ReportData src, List<List<dynamic>> pages)
  async {
//    scale = height / width;
    var data = src.calc;
    graphWidth = 23.25;
    graphHeight = 6.5;
    if (!showBasalDay && !showBasalProfile)graphHeight += basalHeight + 1;
    if (!showLegend) graphHeight += 2.5;
    basalTop = 2.0;
    if (!showNotes)basalTop -= notesHeight;
    graphBottom = graphHeight;
    if (showGlucTable)
    {
      graphHeight -= glucTableHeight;
    }

    lineWidth = cm(0.03);

    for (int i = 0; i < data.days.length; i++)
    {
      DayData day = data.days[sortReverse ? data.days.length - 1 - i : i];
      if (day.entries.length != 0 || day.treatments.length != 0)
        pages.add(getPage(day, src));
      else
        pages.add(getEmptyForm(src));

/*
      if (i < data.days.length - 1)
      {
        if (!isSmall || (offsetY == height && offsetX == width))
        {
          addPageBreak(pages.last.last);
          offsetX = 0.0;
          offsetY = 0.0;
        }
        else if (offsetX == width)
        {
          offsetX = 0.0;
          offsetY += height;
        }
        else
        {
          offsetX = width;
        }
      }
// */
    }
//    _isPortrait = true;
    title = _titleGraphic;
  }

  dynamic glucLine(dynamic points)
  => {"type": "polyline", "lineWidth": cm(lw), "closePath": false, "lineColor": colValue, "points": points};

  getPage(DayData day, ReportData src)
  {
    title = _titleGraphic;
    double collMinutes = sumNarrowValues ? 60 : -1;
    double xo = xorg;
    double yo = yorg;
    titleInfo = fmtDate(day.date, null, false, true);
    glucMax = -1000.0;
    ieMax = 0.0;
    collInsulin.clear();
    collCarbs.clear();
    collInsulin.add(CollectInfo(DateTime(day.date.year, day.date.month, day.date.day, 0, 0, 0)));
    collCarbs.add(CollectInfo(DateTime(day.date.year, day.date.month, day.date.day, 0, 0, 0)));
/*
    math.Random rnd = math.Random();
    for (int i = 0; i < 1440; i += 5)
    {
      TreatmentData t = TreatmentData();
      t.createdAt = DateTime(day.date.year, day.date.month, day.date.day, 0, i);
      t.eventType = "meal bolus";
      t.insulin = 1.0 + rnd.nextInt(6);
      t.carbo(5.0 + rnd.nextInt(12));
      t.glucoseType = "norm";
      t.isSMB = false;
      day.treatments.add(t);
    }
    day.treatments.sort((a, b)
    => a.createdAt.compareTo(b.createdAt));
*/
    for (EntryData entry in day.entries)
      glucMax = math.max(entry.gluc, glucMax);
    for (EntryData entry in day.bloody)
      glucMax = math.max(entry.mbg, glucMax);
    profMax = -1000.0;
    if (showBasalProfile)
    {
      for (ProfileEntryData entry in day.basalData.store.listBasal)
        profMax = math.max(entry.value ?? 0, profMax);
    }
    if (showBasalDay)
    {
      for (ProfileEntryData entry in day.profile)
        profMax = math.max(entry.value ?? 0, profMax);
    }
    for (TreatmentData entry in day.treatments)
    {
      if (entry.glucoseType.toLowerCase() == "finger")
        glucMax = math.max((g.glucMGDL ? 1 : 18.02) * entry.glucose, glucMax);
      ieMax = math.max(entry.bolusInsulin, ieMax);
    }

    int gridLines = (glucMax / 50).ceil();
    double lineHeight = gridLines == 0 ? 0 : graphHeight / gridLines;
    double colWidth = graphWidth / 24;

    var vertLines = {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "canvas": []};
    var horzLines = {"relativePosition": {"x": cm(xo - 0.2), "y": cm(yo)}, "canvas": []};
    var horzLegend = {"stack": []};
    var vertLegend = {"stack": []};
    var graphGluc = {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "canvas": []};
    var graphLegend = {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "stack": []};
    var glucTable = {"relativePosition": {"x": cm(xo), "y": cm(yo + graphHeight)}, "stack": []};
    var glucTableCvs = {"relativePosition": {"x": cm(xo), "y": cm(yo + graphHeight)}, "canvas": []};
    var graphCarbs = {
      "stack": [
        {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "canvas": []},
        {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "stack": []}
      ]
    };
    var graphInsulin = {
      "stack": [
        {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "canvas": []},
        {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "stack": []}
      ]
    };
    var pictures = {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "stack": []};

    List vertCvs = vertLines["canvas"] as List;
    List horzCvs = horzLines["canvas"] as List;
    List horzStack = horzLegend["stack"];
    List vertStack = vertLegend["stack"];
    List graphGlucCvs = graphGluc["canvas"];
    // draw vertical lines with times below graphic
    for (var i = 0; i < 25; i++)
    {
      vertCvs.add({
        "type": "line",
        "x1": cm(i * colWidth),
        "y1": cm(0),
        "x2": cm(i * colWidth),
        "y2": cm(graphBottom),
        "lineWidth": cm(lw),
        "lineColor": i > 0 && i < 24 ? lc : lcFrame
      });
      if (i < 24)horzStack.add({
        "relativePosition": {"x": cm(xo + i * colWidth), "y": cm(yo + graphBottom + 0.05)},
        "text": fmtTime(i),
        "fontSize": fs(8)
      });
    }

    glucMax = 0.0;
    if (lineHeight == 0)
    {
      return [headerFooter(), {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "text": msgMissingData}];
    }
    for (var i = 0; i <= gridLines; i++)
    {
      horzCvs.add({
        "type": "line",
        "x1": cm(-0.2),
        "y1": cm((gridLines - i) * lineHeight - lw / 2),
        "x2": cm(24 * colWidth + 0.2),
        "y2": cm((gridLines - i) * lineHeight - lw / 2),
        "lineWidth": cm(lw),
        "lineColor": i > 0 ? lc : lcFrame
      });

      if (i > 0)
      {
        String text = "${glucFromData(fmtNumber(i * 50, 0))}\n${getGlucInfo()["unit"]}";
        vertStack.add({
          "relativePosition": {"x": cm(xo - 1.1), "y": cm(yo + (gridLines - i) * lineHeight - 0.25)},
          "text": text,
          "fontSize": fs(8)
        });
        vertStack.add({
          "relativePosition": {"x": cm(xo + 24 * colWidth + 0.3), "y": cm(yo + (gridLines - i) * lineHeight - 0.25)},
          "text": text,
          "fontSize": fs(8)
        });
      }
    }
    glucMax = gridLines * 50.0;
    for (EntryData entry in day.bloody)
    {
      double x = glucX(entry.time);
      double y = glucY(entry.mbg);
      graphGlucCvs.add({"type": "rect", "x": cm(x), "y": cm(y), "w": cm(0.1), "h": cm(0.1), "color": colBloodValues});
    }
    for (TreatmentData t in day.treatments)
    {
      if (t.glucoseType.toLowerCase() == "finger")
      {
        double x = glucX(t.createdAt);
        double y = glucY((g.glucMGDL ? 1 : 18.02) * t.glucose);
        graphGlucCvs.add({"type": "rect", "x": cm(x), "y": cm(y), "w": cm(0.1), "h": cm(0.1), "color": colBloodValues});
      }
    }

    dynamic points = [];
    EntryData last = null;
    for (EntryData entry in day.entries)
    {
      double x = glucX(entry.time);
      double y = glucY(entry.gluc);
      if (entry.gluc < 0)
      {
        if (last != null && last.gluc >= 0)
        {
          graphGlucCvs.add(glucLine(points));
          points = [];
        }
      }
      else
      {
        points.add({"x": cm(x), "y": cm(y)});
      }
      last = entry;
    }
    graphGlucCvs.add(glucLine(points));

    bool hasLowGluc = false;
    bool hasNormGluc = false;
    bool hasHighGluc = false;
    if (showGlucTable)
    {
      for (int i = 0; i < 48; i++)
      {
        int hours = i ~/ 2;
        int minutes = (i % 2) * 30;
        DateTime check = DateTime(0, 1, 1, hours, minutes);
        EntryData entry = day.findNearest(day.entries, null, check, maxMinuteDiff: 15);
        double x = glucX(check) + 0.02;
        if (entry != null)
        {
          String col = colNorm;
          if (entry.gluc > day.basalData.targetHigh)
          {
            col = colHigh;
            hasHighGluc = true;
          }
          else if (entry.gluc < day.basalData.targetLow)
          {
            col = colLow;
            hasLowGluc = true;
          }
          else
          {
            hasNormGluc = true;
          }
          (glucTableCvs["canvas"] as List).add({
            "type": "rect",
            "x": cm(glucX(check)),
            "y": cm(0),
            "w": cm(graphWidth / 1440 * 30),
            "h": cm(glucTableHeight),
            "color": col
          });
          (glucTable["stack"] as List).add({
            "relativePosition": {"x": cm(x), "y": cm(i % 2 == 0 ? 0 : glucTableHeight / 2)},
            "text": glucFromData(entry.gluc),
            "color": colGlucValues,
            "fontSize": fs(7)
          });
        }
        if (i % 2 == 1)
        {
          (glucTableCvs["canvas"] as List).add({
            "type": "line",
            "x1": cm(glucX(check)),
            "y1": cm(glucTableHeight * 0.75),
            "x2": cm(glucX(check)),
            "y2": cm(glucTableHeight),
            "lineWidth": cm(lw),
            "lineColor": lc
          });
        }
        if (entry != null)
        {
          dynamic found = day.findNearest(day.bloody, day.treatments, check, maxMinuteDiff: 15);
          if (found is EntryData)
          {
            (glucTable["stack"] as List).add({
              "relativePosition": {"x": cm(x), "y": cm(i % 2 != 0 ? 0 : glucTableHeight / 2)},
              "text": glucFromData(found.mbg),
              "color": colBloodValues,
              "fontSize": fs(7)
            });
          }
          else if (found is TreatmentData)
          {
            (glucTable["stack"] as List).add({
              "relativePosition": {"x": cm(x), "y": cm(i % 2 != 0 ? 0 : glucTableHeight / 2)},
              "text": glucFromData(found.glucose),
              "color": colBloodValues,
              "fontSize": fs(7)
            });
          }
        }
      }
      (glucTableCvs["canvas"] as List).add({
        "type": "line",
        "x1": cm(0),
        "y1": cm(glucTableHeight),
        "x2": cm(graphWidth),
        "y2": cm(glucTableHeight),
        "lineWidth": cm(lw),
        "lineColor": lcFrame
      });
    }

    bool hasCatheterChange = false;
    bool hasSensorChange = false;
    bool hasAmpulleChange = false;
    bool hasCarbs = false;
    bool hasBolus = false;
    bool hasCollectedValues = false;
    List<double> noteLines = List<double>();
    for (TreatmentData t in day.treatments)
    {
      double x, y;
      String type = t.eventType.toLowerCase();
      if (type == "temp basal")continue;
      if ((t.carbs > 0 || t.eCarbs > 0) && showCarbs)
      {
        x = glucX(t.createdAt);
        if (t.isECarb)
        {
          paintECarbs(t.eCarbs, x, graphHeight - lw, graphCarbs["stack"][0]["canvas"] as List);
        }
        else
        {
          y = carbY(t.carbs);
          (graphCarbs["stack"][0]["canvas"] as List).add({
            "type": "line",
            "x1": cm(x),
            "y1": cm(y),
            "x2": cm(x),
            "y2": cm(graphHeight - lw),
            "lineColor": colCarbs,
            "lineWidth": cm(0.1),
          });
          if (t.createdAt
                .difference(collCarbs.last.start)
                .inMinutes < collMinutes)collCarbs.last.fill(t.createdAt, t.carbs);
          else
            collCarbs.add(CollectInfo(t.createdAt, t.carbs));
        }
        hasCarbs = true;
      }
      if (showInsulin)
      {
        if (t.bolusInsulin > 0 && !t.isSMB)
        {
          x = glucX(t.createdAt);
          y = bolusY(t.bolusInsulin);
          (graphInsulin["stack"][0]["canvas"] as List).add({
            "type": "line",
            "x1": cm(x),
            "y1": cm(0),
            "x2": cm(x),
            "y2": cm(y),
            "lineColor": colBolus,
            "lineWidth": cm(0.1),
          });

          if (t.createdAt
                .difference(collInsulin.last.start)
                .inMinutes < collMinutes)collInsulin.last.fill(t.createdAt, t.bolusInsulin);
          else
            collInsulin.add(CollectInfo(t.createdAt, t.bolusInsulin));
          hasBolus = true;
        }
        if (showSMB && t.isSMB && t.insulin > 0)
        {
          EntryData entry = day.findNearest(day.entries, null, t.createdAt);
          x = glucX(t.createdAt);
          if (entry != null && showSMBAtGluc)
          {
            y = glucY(entry.gluc);
          }
          else
          {
            y = glucY(src.targetValue(t.createdAt)) + lw / 2;
          }
          paintSMB(t.insulin, x, y, graphInsulin["stack"][0]["canvas"] as List);
        }
      }
      if (type == "site change" && showPictures)
      {
        double x = glucX(t.createdAt) - 0.3;
        double y = graphHeight - 0.6;
        (pictures["stack"] as List).add(
          {"relativePosition": {"x": cm(x), "y": cm(y)}, "image": "katheter.print", "width": cm(0.8)});
        (pictures["stack"] as List).add({
          "relativePosition": {"x": cm(x + 0.33), "y": cm(y + 0.04)},
          "text": "${fmtTime(t.createdAt)}",
          "fontSize": fs(5),
          "color": "white"
        });
        hasCatheterChange = true;
      }
      else if (type == "sensor change" && showPictures)
      {
        double x = glucX(t.createdAt) - 0.3;
        double y = graphHeight - 0.6;
        (pictures["stack"] as List).add(
          {"relativePosition": {"x": cm(x), "y": cm(y)}, "image": "sensor.print", "width": cm(0.6)});
        (pictures["stack"] as List).add({
          "relativePosition": {"x": cm(x + 0.0), "y": cm(y + 0.34)},
          "columns": [ {
            "width": cm(0.6),
            "text": "${fmtTime(t.createdAt)}",
            "fontSize": fs(5),
            "color": "white",
            "alignment": "center"
          }
          ]
        });
        hasSensorChange = true;
      }
      else if (type == "insulin change" && showPictures)
      {
        double x = glucX(t.createdAt) - 0.3;
        double y = graphHeight - 0.6;
        (pictures["stack"] as List).add(
          {"relativePosition": {"x": cm(x), "y": cm(y)}, "image": "ampulle.print", "width": cm(0.8)});
        (pictures["stack"] as List).add({
          "relativePosition": {"x": cm(x + 0.33), "y": cm(y + 0.1)},
          "text": "${fmtTime(t.createdAt)}",
          "fontSize": fs(5),
          "color": "white"
        });
        hasAmpulleChange = true;
      }

      if (showNotes && (t.notes ?? "").isNotEmpty && !t.isECarb)
      {
        double x = glucX(t.createdAt);
// *** line length estimation ***
// the following code is used to estimate the length of the note-lines for
// trying to avoid overlapping.
        int idx = noteLines.indexWhere((v)
        => v < x);
        bool isMultiline = t.notes.indexOf("\n") > 0;
        int len = t.notes.indexOf("\n") > 0 ? t.notes.indexOf("\n") : t.notes.length;
        double pos = x + len * 0.15;
        if (idx < 0)
        {
          noteLines.add(pos);
          idx = noteLines.length - 1;
        }
        else
        {
          noteLines[idx] = pos;
        }

        if (isMultiline)
        {
          List<String> lines = t.notes.split("\n");
          for (int i = 0; i < lines.length; i++)
          {
            pos = x + lines[i].length * 0.15;
            if (idx + i >= noteLines.length)noteLines.add(0);
            noteLines[idx + i] = math.max(noteLines[idx + i], pos);
          }
        }
// *** end of linelength estimation ***
        if (idx < (isMultiline ? 1 : 3))
        {
          double y = graphBottom + notesTop + idx * notesHeight;
          double top = graphBottom;
          if (showInfoLinesAtGluc)
          {
            EntryData e = day.findNearest(day.entries, null, t.createdAt);
            if (e != null)top = glucY(e.gluc);
          }
          graphGlucCvs.add({
            "type": "line",
            "x1": cm(x),
            "y1": cm(top),
            "x2": cm(x),
            "y2": cm(y + notesHeight),
            "lineWidth": cm(lw),
            "lineColor": t.duration > 0 ? colDurationNotesLine : colNotesLine
          });
          (graphLegend["stack"] as List).add({
            "relativePosition": {"x": cm(x + 0.05), "y": cm(y + notesHeight - 0.25)},
            "text": t.notes,
            "fontSize": fs(8),
            "alignment": "left",
            "color": t.duration > 0 ? colDurationNotes : colNotes
          });
          if (t.duration > 0)
          {
            x = glucX(t.createdAt.add(Duration(minutes: t.duration)));
            graphGlucCvs.add({
              "type": "line",
              "x1": cm(x),
              "y1": cm(graphBottom + 0.35),
              "x2": cm(x),
              "y2": cm(y + 0.1),
              "lineWidth": cm(lw),
              "lineColor": colDurationNotesLine
            });
          }
        }
      }
/*
      if (cobPoints.length > 0)cobPoints.add({"x": cobPoints.last["x"], "y": cobPoints.first["y"]});
      graphCvs.add(cob);
*/
    }

    for (CollectInfo info in collInsulin)
    {
      if (info.sum == 0.0)continue;
      DateTime date = info.start.add(Duration(minutes: info.end
                                                         .difference(info.start)
                                                         .inMinutes ~/ 2));
      double y = sumNarrowValues ? -0.5 : bolusY(info.max);
      String text = "${fmtBasal(info.sum)} ${msgInsulinUnit}";
      if (info.count > 1)
      {
        text = "[$text]";
        hasCollectedValues = true;
      }
/*
      (graphInsulin["stack"][1]["stack"] as List).add({
        "relativePosition": {"x": cm(x - 0.3), "y": cm(y + 0.05),},
        "text": text,
        "fontSize": fs(8),
        "color": colBolus
      });
// */
      (graphInsulin["stack"][1]["stack"] as List).add({
        "relativePosition": {"x": cm(glucX(info.start) - 0.05), "y": cm(y),},
        "text": text,
        "fontSize": fs(8),
        "color": colBolus
      });
    }
    for (CollectInfo info in collCarbs)
    {
      if (info.sum == 0.0)continue;
      DateTime date = info.start.add(Duration(minutes: info.end
                                                         .difference(info.start)
                                                         .inMinutes ~/ 2));
      double y = carbY(info.max);
      String text = "${msgKH(fmtNumber(info.sum))}";
      if (info.count > 1)
      {
        text = "[$text]";
        hasCollectedValues = true;
      }
      (graphCarbs["stack"][1]["stack"] as List).add(
        {"relativePosition": {"x": cm(glucX(info.start) - 0.05), "y": cm(y - 0.35),}, "text": text, "fontSize": fs(8)});
    }

    DateTime date = DateTime(day.date.year, day.date.month, day.date.day);
    ProfileGlucData profile = src.profile(date);
    double yHigh = glucY(math.min(glucMax, src.status.settings.thresholds.bgTargetTop.toDouble()));
    double yLow = glucY(src.status.settings.thresholds.bgTargetBottom.toDouble());
    List targetValues = [];
    double lastTarget = -1;
    for (var i = 0; i < profile.store.listTargetLow.length; i++)
    {
      double low = profile.store.listTargetLow[i].value;
      double high = profile.store.listTargetHigh[i].value;
      double x = glucX(profile.store.listTargetLow[i].time(day.date));
      double y = glucY((low + high) / 2);
      if (lastTarget >= 0)targetValues.add({"x": cm(x), "y": cm(lastTarget)});
      targetValues.add({"x": cm(x), "y": cm(y)});
      lastTarget = y;
    }
    targetValues.add({
      "x": cm(glucX(DateTime(
        0,
        1,
        1,
        23,
        59,
        59,
        999))),
      "y": cm(lastTarget)
    });

    var limitLines = {
      "relativePosition": {"x": cm(xo), "y": cm(yo)},
      "canvas": [
        {
          "type": "rect",
          "x": cm(0.0),
          "y": cm(yHigh),
          "w": cm(24 * colWidth),
          "h": cm(yLow - yHigh),
          "color": colTargetArea,
          "fillOpacity": 0.3
        },
        {
          "type": "line",
          "x1": cm(0.0),
          "y1": cm(yHigh),
          "x2": cm(24 * colWidth),
          "y2": cm(yHigh),
          "lineWidth": cm(lw),
          "lineColor": colTargetArea
        },
        {
          "type": "polyline",
          "lineWidth": cm(lw),
          "closePath": false,
          "lineColor": colTargetValue,
          "points": targetValues
        },
        {
          "type": "line",
          "x1": cm(0.0),
          "y1": cm(yLow),
          "x2": cm(24 * colWidth),
          "y2": cm(yLow),
          "lineWidth": cm(lw),
          "lineColor": colTargetArea
        },
        {"type": "rect", "x": 0, "y": 0, "w": 0, "h": 0, "color": "#000", "fillOpacity": 1}
      ]
    };
    var y = yo + lineHeight * gridLines;
    if (showBasalProfile || showBasalDay)y += 1.2 + basalHeight + basalTop;
    else
      y += basalTop;

    LegendData legend = LegendData(cm(xo), cm(y), cm(7.0), 6);
    double tdd = day.ieBasalSum + day.ieBolusSum;
    dynamic infoTable = {};

    if (showLegend)
    {
      addLegendEntry(legend, colValue, msgGlucosekurve, isArea: false);
      String text;
      if (hasCarbs)
      {
        text = "${fmtNumber(day.carbs, 0)}";
        addLegendEntry(legend, colCarbs, msgCarbs(text), isArea: false, lineWidth: 0.1);
      }
      if (hasBolus)addLegendEntry(
        legend, colBolus, msgBolusInsulin("${fmtBasal(day.ieBolusSum)} ${msgInsulinUnit}"), isArea: false,
        lineWidth: 0.1);
      if (showBasalDay)
      {
        text = "${fmtBasal(day.ieBasalSum)} ${msgInsulinUnit}";
        addLegendEntry(legend, colBasalDay, msgBasalrateDay(text), isArea: true);
      }
      if (showBasalProfile)
      {
        text = "${fmtBasal(day.basalData.store.ieBasalSum)} ${msgInsulinUnit}";
        addLegendEntry(legend, colBasalProfile, msgBasalrateProfile(text), isArea: false);
      }
      text = "${fmtBasal(tdd)} ${msgInsulinUnit}";
      addLegendEntry(legend, "", msgLegendTDD(text), graphText: msgTDD);
      String v1 = glucFromData(src.status.settings.thresholds.bgTargetBottom.toDouble());
      String v2 = glucFromData(src.status.settings.thresholds.bgTargetTop.toDouble());
      addLegendEntry(legend, colTargetArea, msgTargetArea(v1, v2, getGlucInfo()["unit"]));
      addLegendEntry(legend, colTargetValue,
        msgTargetValue("${glucFromData((profile.targetHigh + profile.targetLow) / 2)} ${getGlucInfo()["unit"]}"),
        isArea: false);
      if (hasCollectedValues)addLegendEntry(legend, "", msgCollectedValues, graphText: "[0,0]");
      if (hasCatheterChange)addLegendEntry(
        legend, "", msgCatheterChange, image: "katheter.print", imgWidth: 0.5, imgOffsetY: 0.15);
      if (hasSensorChange)addLegendEntry(
        legend, "", msgSensorChange, image: "sensor.print", imgWidth: 0.5, imgOffsetY: -0.05);
      if (hasAmpulleChange)addLegendEntry(
        legend, "", msgAmpulleChange, image: "ampulle.print", imgWidth: 0.4, imgOffsetY: 0.1);
      if (showGlucTable)
      {
        if (hasLowGluc)addLegendEntry(
          legend, colLow, msgGlucLow, graphText: glucFromData(day.basalData.targetLow), newColumn: true);
        if (hasNormGluc)addLegendEntry(legend, colNorm, msgGlucNorm,
          graphText: glucFromData((day.basalData.targetLow + day.basalData.targetHigh) / 2), newColumn: !hasLowGluc);
        if (hasHighGluc)addLegendEntry(legend, colHigh, msgGlucHigh, graphText: glucFromData(day.basalData.targetHigh));
      }


      var infoBody = [];
      infoTable = {
        "relativePosition": {"x": cm(xo + graphWidth - 3.5), "y": cm(y)},
        "table": {"margins": [0, 0, 0, 0], "widths": [cm(2.4), cm(1.1)], "body": infoBody},
        "layout": "noBorders"
      };

      infoBody.add([
        {"text": msgHbA1C, "fontSize": fs(10)},
        {"text": "${hba1c(day.mid)} %", "color": colHbA1c, "fontSize": fs(10), "alignment": "right"}
      ]);
      double prz = day.ieBasalSum / (day.ieBasalSum + day.ieBolusSum) * 100;
      infoBody.add([
        {"text": "Basal ges.", "fontSize": fs(10)},
        {"text": "${fmtNumber(prz, 1, false)} %", "color": colBolus, "fontSize": fs(10), "alignment": "right"}
      ]);
      prz = day.ieBolusSum / (day.ieBasalSum + day.ieBolusSum) * 100;
      infoBody.add([
        {"text": "Bolus ges.", "fontSize": fs(10)},
        {"text": "${fmtNumber(prz, 1, false)} %", "color": colBolus, "fontSize": fs(10), "alignment": "right"}
      ]);
    }

    var profileBasal = showBasalProfile ? getBasalGraph(day, true, showBasalDay, xo, yo) : null;
    var dayBasal = showBasalDay ? getBasalGraph(day, false, false, xo, yo) : null;

    if (showBasalProfile)
    {
      profileBasal["stack"].add({
        "relativePosition": {"x": cm(xo), "y": cm(yo + graphHeight + basalHeight + basalTop + 0.1)},
        "columns": [ {
          "width": cm(basalWidth),
          "text": "${msgTDD} ${fmtBasal(tdd)} ${msgInsulinUnit}",
          "fontSize": fs(20),
          "alignment": "center",
          "color": colBasalDay
        }
        ]
      },);
    }

    String error = null;
/*
    if (!g.checkJSON(glucTableCvs))error = "glucTableCvs";
    if (!g.checkJSON(vertLegend))error = "vertLegend";
    if (!g.checkJSON(vertLines))error = "vertLines";
    if (!g.checkJSON(horzLegend))error = "horzLegend";
    if (!g.checkJSON(horzLines))error = "horzLines";
*/
    if (error != null)
    {
      return [
        headerFooter(), {"relativePosition": {"x": cm(xo), "y": cm(yo)}, "text": "Fehler bei $error", "color": "red"}];
    }

    return [
      headerFooter(),
      glucTableCvs,
      vertLegend,
      vertLines,
      horzLegend,
      horzLines,
      limitLines,
      pictures,
      graphGluc,
      graphInsulin,
      graphCarbs,
      glucTable,
      dayBasal,
      profileBasal,
      graphLegend,
      legend.asOutput,
      infoTable
    ];
  }

  getBasalGraph(DayData day, bool useProfile, bool displayProfile, double xo, double yo)
  {
    List<ProfileEntryData> data;
    double basalSum;
    String color;

    if (useProfile)
    {
      data = day.basalData.store.listBasal;
      basalSum = day.basalData.store.ieBasalSum;
      color = colBasalProfile;
    }
    else
    {
      data = day.profile;
      basalSum = day.ieBasalSum;
      color = colBasalDay;
    }
    var basalCvs = [];
    var ret = {
      "stack": [{"relativePosition": {"x": cm(xo), "y": cm(yo + graphHeight + basalTop)}, "canvas": basalCvs}]
    };
    if (basalSum != 0)ret["stack"].add({
      "relativePosition": {"x": cm(xo), "y": cm(yo + graphHeight + basalHeight + basalTop + 0.1)},
      "columns": [ {
        "width": cm(basalWidth),
        "text": "${fmtBasal(basalSum)} ${msgInsulinUnit}",
        "fontSize": fs(20),
        "alignment": displayProfile ? "right" : "left",
        "color": color
      }
      ]
    },);
    double lastY = -1.0;
    var areaPoints = [];
    var area = {
      "type": "polyline",
      "lineWidth": cm(lw),
      "closePath": !displayProfile,
      "color": !displayProfile ? blendColor(color, "#ffffff", 0.7) : null,
      "lineColor": color,
      "dash": displayProfile ? {"length": cm(0.1), "space": cm(0.05)} : {},
      "points": areaPoints,
//      "fillOpacity": opacity
    };

    var temp = List<ProfileEntryData>();
    for (ProfileEntryData entry in data)
      temp.add(entry);
    if (useProfile)
    {
      temp.sort((a, b)
      => a.time(day.date, useProfile).compareTo(b.time(day.date, useProfile)));

      if (temp.length == 0)temp.add(ProfileEntryData(ProfileTimezone(Globals.refTimezone)));
      if (temp[0].timeAsSeconds != -temp[0].localDiff * 60 * 60)
      {
        ProfileEntryData clone = temp[0].clone(DateTime(0, 1, 1, -temp[0].localDiff, 0));
        temp.insert(0, clone);
      }
    }

    if (!displayProfile)areaPoints.add({"x": cm(basalX(DateTime(0, 1, 1, 0, 0))), "y": cm(basalY(0.0))});
    for (ProfileEntryData entry in temp)
    {
      double x = basalX(entry.time(day.date, useProfile));
      double y = basalY(entry.value); //basalY(entry.adjustedValue(entry.value));
      if (lastY >= 0)areaPoints.add({"x": cm(x), "y": cm(lastY)});
      areaPoints.add({"x": cm(x), "y": cm(y)});
      lastY = y;
    }
    if (lastY >= 0)areaPoints.add({"x": cm(basalX(DateTime(0, 1, 1, 23, 59))), "y": cm(lastY)});
    if (!displayProfile)areaPoints.add({"x": cm(basalX(DateTime(0, 1, 1, 23, 59))), "y": cm(basalY(0.0))});
    basalCvs.add(area);
//    basalCvs.add({"type": "rect", "x": 0, "y": 0, "w": 1, "h": 1, "fillOpacity": 1});
    return ret;
  }

  paintECarbs(double eCarbs, double x, double y, List cvs)
  {
    double h = graphHeight - carbY(eCarbs);
    cvs.add({
      "type": "polyline",
      "closePath": true,
      "_lineColor": "#000000",
      "color": colCarbs,
      "lineWidth": cm(0),
      "points": [{"x": cm(x), "y": cm(y - h - 0.1)}, {"x": cm(x + 0.1), "y": cm(y)}, {"x": cm(x - 0.1), "y": cm(y)}],
    });
  }

  paintSMB(double insulin, double x, double y, List cvs)
  {
    double h = smbY(insulin) * 2;
    cvs.add({
      "type": "polyline",
      "closePath": true,
      "_lineColor": "#000000",
      "color": colBolus,
      "lineWidth": cm(0),
      "points": [
        {"x": cm(x), "y": cm(y)}, {"x": cm(x + 0.1), "y": cm(y - h - 0.1)}, {"x": cm(x - 0.1), "y": cm(y - h - 0.1)}],
    });
  }
}