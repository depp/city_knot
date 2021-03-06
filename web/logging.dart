/*
Copyright Robert Muth <robert@muth.org>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 3
of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

library logging;

int gLogLevel = 1;

String _D2(int n) {
  if (n >= 10) return "${n}";
  return "0${n}";
}

String _D3(int n) {
  if (n >= 100) return "${n}";
  if (n >= 10) return "0${n}";
  return "00${n}";
}

String TimeFormat( DateTime dt ) {
    return "${_D2(dt.hour)}:${_D2(dt.minute)}:${_D2(dt.second)}.${_D3(dt.millisecond)}";
}


String DurationFormat(double mSec) {
   return TimeFormat(DateTime.fromMillisecondsSinceEpoch(mSec.floor(), isUtc: true));
}

String _Prefix(String kind) {
  return kind + ":"  + TimeFormat(DateTime.now()) + ": ";
}

void LogInfo(String s) {
  if (gLogLevel > 0) {
    print(_Prefix("I") + s);
  }
}

void LogDebug(String s) {
  if (gLogLevel > 1) {
    print(_Prefix("D") + s);
  }
}

void LogError(String s) {
  print(_Prefix("E") + s);
}

void LogWarn(String s) {
  print(_Prefix("W") + s);
}
